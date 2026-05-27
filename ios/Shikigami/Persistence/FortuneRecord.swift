import Foundation
import SwiftData

// docs/design.md §4 データモデル準拠。鑑定履歴をローカルキャッシュとして保存する。
// inputHash = SHA256(localUserId, engine, topic, normalizedQuestion, shikigamiId, gogyo, scoreBand, historySummaryHash, dateJst)
@Model
final class FortuneRecord {
    var id: UUID
    var engine: String
    var topic: String
    var inputHash: String
    var response: String
    var createdAt: Date

    init(id: UUID = UUID(), engine: String, topic: String, inputHash: String, response: String, createdAt: Date = .now) {
        self.id = id
        self.engine = engine
        self.topic = topic
        self.inputHash = inputHash
        self.response = response
        self.createdAt = createdAt
    }
}
