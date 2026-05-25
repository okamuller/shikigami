import SwiftUI

enum FortuneEngine: String, CaseIterable, Codable, Identifiable {
    case seimei
    case nanboku

    var id: String { rawValue }

    var nameKey: String {
        switch self {
        case .seimei: return "character.seimei.name"
        case .nanboku: return "character.nanboku.name"
        }
    }

    var titleKey: String {
        switch self {
        case .seimei: return "character.seimei.title"
        case .nanboku: return "character.nanboku.title"
        }
    }

    var ctaKey: String {
        switch self {
        case .seimei: return "fortune.input.cta.seimei"
        case .nanboku: return "fortune.input.cta.nanboku"
        }
    }

    var accentColor: Color {
        switch self {
        case .seimei: return .oracleGold
        case .nanboku: return .jadeGreen
        }
    }

    var symbolName: String {
        switch self {
        case .seimei: return "sparkles"
        case .nanboku: return "leaf.fill"
        }
    }
}

struct Fortune: Identifiable, Codable {
    let id: UUID
    let text: String
    let cached: Bool
    let isFallback: Bool
    let tokensIn: Int
    let tokensOut: Int
    let createdAt: Date
    let topic: Topic

    enum CodingKeys: String, CodingKey {
        case id, text, cached, topic
        case isFallback  = "is_fallback"
        case tokensIn    = "tokens_in"
        case tokensOut   = "tokens_out"
        case createdAt   = "created_at"
    }
}

enum Topic: String, CaseIterable, Codable, Identifiable {
    case love    = "love"
    case work    = "work"
    case money   = "money"
    case health  = "health"
    case family  = "family"
    case destiny = "destiny"

    var id: String { rawValue }

    var labelJa: String {
        switch self {
        case .love:    return NSLocalizedString("topic.love", comment: "")
        case .work:    return NSLocalizedString("topic.work", comment: "")
        case .money:   return NSLocalizedString("topic.money", comment: "")
        case .health:  return NSLocalizedString("topic.health", comment: "")
        case .family:  return NSLocalizedString("topic.family", comment: "")
        case .destiny: return NSLocalizedString("topic.destiny", comment: "")
        }
    }

    var icon: String {
        switch self {
        case .love:    return "♡"
        case .work:    return "⚔"
        case .money:   return "◎"
        case .health:  return "✦"
        case .family:  return "⬡"
        case .destiny: return "☿"
        }
    }

    var accentColor: Color {
        switch self {
        case .love:    return .crimsonRed
        case .work:    return .oracleGold
        case .money:   return .jadeGreen
        case .health:  return Color(hex: "#3A7BD5")
        case .family:  return .fujiPurple
        case .destiny: return Color(hex: "#888888")
        }
    }
}
