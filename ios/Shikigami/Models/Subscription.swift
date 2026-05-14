import Foundation

enum SubscriptionTier: String, Codable {
    case free    = "free"
    case premium = "premium"
    case divine  = "divine"

    var maxDailyFortunes: Int {
        switch self {
        case .free:    return 5
        case .premium: return 50
        case .divine:  return Int.max
        }
    }
}

struct Subscription: Codable {
    let tier: SubscriptionTier
    let expiresAt: Date?

    enum CodingKeys: String, CodingKey {
        case tier
        case expiresAt = "expires_at"
    }
}
