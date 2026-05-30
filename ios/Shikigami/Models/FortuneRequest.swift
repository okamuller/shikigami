import Foundation

// claude-proxy Edge Function へのリクエストボディ（docs/design.md §2.1 準拠）
struct FortuneRequest: Encodable {
    let engine: String
    let topic: String
    let question: String
    let meishiki: MeishikiPayload
    // FR-EN-04: LocalFortuneGenerator のテンプレートバリアント選択に使用
    let historySummaryHash: String

    init(engine: String, topic: String, question: String, meishiki: MeishikiPayload, historySummaryHash: String = "") {
        self.engine = engine
        self.topic = topic
        self.question = question
        self.meishiki = meishiki
        self.historySummaryHash = historySummaryHash
    }

    enum CodingKeys: String, CodingKey {
        case engine, topic, question, meishiki
        case historySummaryHash = "history_summary_hash"
    }
}

struct MeishikiPayload: Codable {
    let kanIndex: Int
    let shiIndex: Int
    let shikigamiIndex: Int
    let gogyo: String
    let score: Int

    enum CodingKeys: String, CodingKey {
        case kanIndex       = "kan_index"
        case shiIndex       = "shi_index"
        case shikigamiIndex = "shikigami_index"
        case gogyo
        case score
    }
}

struct FortuneAPIResponse: Decodable {
    let id: String
    let text: String
    let cached: Bool
    let isFallback: Bool
    let tokens: TokenUsage

    enum CodingKeys: String, CodingKey {
        case id, text, cached, tokens
        case isFallback = "is_fallback"
    }
}

struct TokenUsage: Decodable {
    let input: Int
    let output: Int
}
