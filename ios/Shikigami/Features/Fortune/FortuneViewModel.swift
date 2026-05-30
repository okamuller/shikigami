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
            // FR-EN-04: fetchRecentRecords は当日より前のレコードのみ返す（FortuneInputView 側で保証）。
            // 同日内の再リクエストでもハッシュが安定しキャッシュが正しく機能する。
            let historySnapshot = fetchRecentRecords?() ?? []
            let summaryHash = buildSummaryHash(from: historySnapshot)
            let hash = buildLocalHash(meishiki: meishiki, summaryHash: summaryHash)

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
                meishiki: meishiki,
                historySummaryHash: summaryHash
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

    // FR-EN-04: 直近履歴 5 件の engine|topic を SHA256 でまとめた履歴サマリーハッシュ
    private func buildSummaryHash(from records: [FortuneRecord]) -> String {
        let seed = records.prefix(5).map { "\($0.engine)|\($0.topic)" }.joined(separator: ",")
        return SHA256.hash(data: Data(seed.utf8)).map { String(format: "%02x", $0) }.joined()
    }

    // docs/design.md §4.1 ローカルキャッシュキー構築
    // scoreBand: 60-69 → low, 70-84 → middle, 85-99 → high
    private func buildLocalHash(meishiki: MeishikiPayload, summaryHash: String) -> String {
        let dateJst = Date().formatted(.iso8601.year().month().day().timeZone(separator: .omitted))
        let normalized = question.trimmingCharacters(in: .whitespacesAndNewlines)
        let band = meishiki.score <= 69 ? "low" : meishiki.score <= 84 ? "middle" : "high"
        let raw = [userId.uuidString, engine.rawValue, selectedTopic.rawValue, normalized,
                   String(meishiki.shikigamiIndex), meishiki.gogyo, band, summaryHash, dateJst].joined(separator: "|")
        return SHA256.hash(data: Data(raw.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}
