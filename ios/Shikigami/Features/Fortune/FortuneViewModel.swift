import Foundation
import Observation

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
            let request = FortuneRequest(
                engine: engine.rawValue,
                topic: selectedTopic.rawValue,
                question: question,
                meishiki: meishiki
            )

            let response = try await claudeClient.generate(request: request)

            fortune = Fortune(
                id: UUID(uuidString: response.id) ?? UUID(),
                text: response.text,
                cached: response.cached,
                isFallback: response.isFallback,
                tokensIn: response.tokensIn,
                tokensOut: response.tokensOut,
                createdAt: .now,
                topic: selectedTopic
            )

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
}
