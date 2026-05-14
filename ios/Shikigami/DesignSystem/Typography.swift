import SwiftUI

enum ShikigamiFont {
    case display   // 大見出し（式神名など）
    case heading   // 見出し
    case body      // 本文（鑑定文）
    case label     // ラベル・補足

    var font: Font {
        switch self {
        case .display: return .custom("YuMincho-Demibold", size: 32, relativeTo: .largeTitle)
            .weight(.semibold)
        case .heading: return .custom("YuMincho-Medium", size: 22, relativeTo: .title2)
        case .body:    return .custom("HiraMinProN-W3", size: 17, relativeTo: .body)
        case .label:   return .custom("HiraMinProN-W3", size: 13, relativeTo: .caption)
        }
    }

    var tracking: CGFloat {
        switch self {
        case .display: return 6
        case .heading: return 4
        case .body:    return 2
        case .label:   return 1
        }
    }
}

extension View {
    func shikigamiFont(_ style: ShikigamiFont) -> some View {
        self.font(style.font).tracking(style.tracking)
    }
}
