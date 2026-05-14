import Foundation

struct AppUser: Identifiable, Codable {
    let id: UUID
    var birthDate: Date?
    var gender: Gender
    var shikigamiId: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case birthDate = "birth_date"
        case gender
        case shikigamiId = "shikigami_id"
    }
}

enum Gender: String, Codable, CaseIterable {
    case yin   = "yin"
    case yang  = "yang"
    case none  = "none"

    var labelJa: String {
        switch self {
        case .yin:  return "陰（女）"
        case .yang: return "陽（男）"
        case .none: return "回答しない"
        }
    }
}
