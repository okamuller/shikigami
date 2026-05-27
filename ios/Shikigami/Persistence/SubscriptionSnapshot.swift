import Foundation
import SwiftData

// docs/design.md §4 データモデル準拠。課金状態のローカルスナップショット。
@Model
final class SubscriptionSnapshot {
    var tier: String
    var expiresAt: Date?

    init(tier: String, expiresAt: Date? = nil) {
        self.tier = tier
        self.expiresAt = expiresAt
    }
}
