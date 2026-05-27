import Foundation

/// 十二天将。
/// .claude/B_logic.md「ENGINE A: 六壬神課エンジン」十二天将テーブル準拠。
/// 表示名のローカライズは `Localizable.strings` の `shikigami.<id>.name` で行う前提（docs/design.md §3.1）。
public struct Shikigami: Equatable, Sendable {
    public enum Kichi: String, Sendable, Equatable {
        case kichi   // 吉
        case chu     // 中
        case kyo     // 凶
    }

    public let id: Int
    public let nameKey: String  // Localizable.strings のキー
    public let nameJa: String   // ローカライズ未読み込み時のフォールバック日本語名
    public let gogyo: Gogyo
    public let kichi: Kichi
    public let meaning: String

    public static let table: [Shikigami] = [
        .init(id: 0,  nameKey: "shikigami.0.name",  nameJa: "貴人", gogyo: .earth, kichi: .kichi, meaning: "高貴・援助・上位の力"),
        .init(id: 1,  nameKey: "shikigami.1.name",  nameJa: "騰蛇", gogyo: .fire,  kichi: .kyo,   meaning: "変化・不安・口舌"),
        .init(id: 2,  nameKey: "shikigami.2.name",  nameJa: "朱雀", gogyo: .fire,  kichi: .chu,   meaning: "文書・言語・知性"),
        .init(id: 3,  nameKey: "shikigami.3.name",  nameJa: "六合", gogyo: .wood,  kichi: .kichi, meaning: "縁結び・協力・和合"),
        .init(id: 4,  nameKey: "shikigami.4.name",  nameJa: "勾陳", gogyo: .earth, kichi: .kyo,   meaning: "停滞・土地・紛争"),
        .init(id: 5,  nameKey: "shikigami.5.name",  nameJa: "青龍", gogyo: .wood,  kichi: .kichi, meaning: "財運・発展・吉祥"),
        .init(id: 6,  nameKey: "shikigami.6.name",  nameJa: "天空", gogyo: .earth, kichi: .chu,   meaning: "虚偽・空白・迷い"),
        .init(id: 7,  nameKey: "shikigami.7.name",  nameJa: "白虎", gogyo: .metal, kichi: .kyo,   meaning: "災難・争い・変動"),
        .init(id: 8,  nameKey: "shikigami.8.name",  nameJa: "太常", gogyo: .earth, kichi: .kichi, meaning: "安定・礼儀・衣食"),
        .init(id: 9,  nameKey: "shikigami.9.name",  nameJa: "玄武", gogyo: .water, kichi: .kyo,   meaning: "隠蔽・盗難・水難"),
        .init(id: 10, nameKey: "shikigami.10.name", nameJa: "太陰", gogyo: .metal, kichi: .chu,   meaning: "女性・隠れ・陰謀"),
        .init(id: 11, nameKey: "shikigami.11.name", nameJa: "天后", gogyo: .water, kichi: .kichi, meaning: "婚姻・母性・豊穣")
    ]

    public static func from(index: Int) -> Shikigami {
        precondition((0..<12).contains(index), "Shikigami index must be 0..<12, got \(index)")
        return table[index]
    }
}

/// 毎朝の通知に使う「式神ひとこと」の日替わり選択。
public struct DailyShikigamiWordSelection: Equatable, Sendable {
    public let shikigami: Shikigami?
    public let templateIndex: Int

    public var shikigamiNameJa: String {
        shikigami?.nameJa ?? "式神"
    }

    public var shikigamiNameKey: String? {
        shikigami?.nameKey
    }

    public var templateLocalizationKey: String {
        "notification.daily.word.\(templateIndex)"
    }
}

public enum DailyShikigamiWordEngine {
    public static let templateCount = 6

    public static func selection(
        shikigamiID: Int?,
        date: Date,
        calendar: Calendar = Calendar(identifier: .gregorian)
    ) -> DailyShikigamiWordSelection {
        let shikigami = shikigamiID.flatMap { id in
            Shikigami.table.indices.contains(id) ? Shikigami.table[id] : nil
        }
        let dayOrdinal = calendar.ordinality(of: .day, in: .era, for: date) ?? 0
        let seed = dayOrdinal + (shikigami?.id ?? 0)
        let templateIndex = ((seed % templateCount) + templateCount) % templateCount

        return DailyShikigamiWordSelection(
            shikigami: shikigami,
            templateIndex: templateIndex
        )
    }
}
