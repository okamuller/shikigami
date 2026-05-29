import Foundation
import Observation
import CryptoKit

@Observable
final class FortuneViewModel {
    var question: String = ""
    var selectedTopic: Topic
    let engine: FortuneEngine
    var isGenerating = false
    var fortune: Fortune?
    var showPaywall = false
    var error: FortuneError?

    private let claudeClient: ClaudeClient
    private let userRepo: UserRepository
    private let userId: UUID
    // FortuneInputView が modelContext 確定後に差し込む (docs/design.md §4 FortuneRecord)
    var saveRecord: ((FortuneRecord) -> Void)?
    var fetchRecord: ((String) -> FortuneRecord?)?
    // FR-EN-04: 直近履歴サマリーハッシュ用
    var fetchRecentRecords: (() -> [FortuneRecord])?

    init(
        engine: FortuneEngine,
        topic: Topic,
        userId: UUID,
        claudeClient: ClaudeClient,
        userRepo: UserRepository
    ) {
        self.engine = engine
        self.selectedTopic = topic
        self.userId = userId
        self.claudeClient = claudeClient
        self.userRepo = userRepo
    }

    var canGenerate: Bool {
        !question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && question.count <= 80
    }

    func generate() async {
        guard canGenerate else { return }
        isGenerating = true
        error = nil

        do {
            let meishiki = loadMeishiki()
            let hash = buildLocalHash(meishiki: meishiki)

            // ローカルキャッシュヒット時は API 呼び出しをスキップ (docs/design.md §4)
            if let cached = fetchRecord?(hash) {
                fortune = Fortune(
                    id: cached.id,
                    text: cached.response,
                    cached: true,
                    isFallback: false,
                    tokensIn: 0,
                    tokensOut: 0,
                    createdAt: cached.createdAt,
                    topic: selectedTopic
                )
                isGenerating = false
                return
            }

            let request = FortuneRequest(
                engine: engine.rawValue,
                topic: selectedTopic.rawValue,
                question: question,
                meishiki: meishiki
            )

            let response = try await claudeClient.generate(request: request)

            let generatedFortune = Fortune(
                id: UUID(uuidString: response.id) ?? UUID(),
                text: response.text,
                cached: response.cached,
                isFallback: response.isFallback,
                tokensIn: response.tokensIn,
                tokensOut: response.tokensOut,
                createdAt: .now,
                topic: selectedTopic
            )
            fortune = generatedFortune

            // 鑑定結果を SwiftData にローカル保存 (docs/design.md §4)
            if !response.cached {
                let record = FortuneRecord(
                    id: generatedFortune.id,
                    engine: engine.rawValue,
                    topic: selectedTopic.rawValue,
                    inputHash: hash,
                    response: response.text
                )
                saveRecord?(record)
            }

        } catch FortuneError.quotaExceeded {
            showPaywall = true
        } catch FortuneError.claudeUnavailable(let fallbackText) {
            // API 障害時はフォールバック文を fortune として表示する（NFR-OF-01）
            fortune = Fortune(
                id: UUID(),
                text: fallbackText,
                cached: false,
                isFallback: true,
                tokensIn: 0,
                tokensOut: 0,
                createdAt: .now,
                topic: selectedTopic
            )
        } catch let e as FortuneError {
            error = e
        } catch {
            self.error = .networkError(error)
        }

        isGenerating = false
    }

    private func loadMeishiki() -> MeishikiPayload {
        let key = "meishiki_\(userId.uuidString)"
        if let data = UserDefaults.standard.data(forKey: key),
           let payload = try? JSONDecoder().decode(MeishikiPayload.self, from: data) {
            return payload
        }
        // フォールバック（オンボーディング前に呼ばれた場合）
        return MeishikiPayload(kanIndex: 0, shiIndex: 0, shikigamiIndex: 0, gogyo: "wood", score: 70)
    }

    // docs/design.md §4.1 ローカルキャッシュキー構築
    // scoreBand: 60-69 → low, 70-84 → middle, 85-99 → high
    // FR-EN-04: 直近 5 件の engine|topic 文字列を historyHash として混入
    private func buildLocalHash(meishiki: MeishikiPayload) -> String {
        let dateJst = Date().formatted(.iso8601.year().month().day().timeZone(separator: .omitted))
        let normalized = question.trimmingCharacters(in: .whitespacesAndNewlines)
        let band = meishiki.score <= 69 ? "low" : meishiki.score <= 84 ? "middle" : "high"
        let recent = fetchRecentRecords?() ?? []
        let summarySeed = recent.prefix(5).map { "\($0.engine)|\($0.topic)" }.joined(separator: ",")
        let summaryHash = SHA256.hash(data: Data(summarySeed.utf8)).map { String(format: "%02x", $0) }.joined()
        let raw = [userId.uuidString, engine.rawValue, selectedTopic.rawValue, normalized,
                   String(meishiki.shikigamiIndex), meishiki.gogyo, band, summaryHash, dateJst].joined(separator: "|")
        return SHA256.hash(data: Data(raw.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}
