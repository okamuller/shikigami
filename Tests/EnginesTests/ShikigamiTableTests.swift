import XCTest
@testable import Engines

/// 十二天将テーブルの整合性。
/// .claude/B_logic.md の表をリグレッションさせないための固定テスト。
final class ShikigamiTableTests: XCTestCase {

    func test_table_has_exactly_twelve_entries() {
        XCTAssertEqual(Shikigami.table.count, 12)
    }

    func test_ids_are_zero_to_eleven_in_order() {
        for (i, s) in Shikigami.table.enumerated() {
            XCTAssertEqual(s.id, i, "Shikigami.table[\(i)].id should be \(i), got \(s.id)")
        }
    }

    func test_name_keys_follow_localization_convention() {
        // docs/design.md §3.1「ローカライズは shikigami.0.name 〜 shikigami.11.name で参照」
        for s in Shikigami.table {
            XCTAssertEqual(s.nameKey, "shikigami.\(s.id).name")
        }
    }

    /// .claude/B_logic.md の表に対する固定マッピング。
    /// docs/design.md §3.1 で表は `(name, gogyo, kichi, meaning)` と定義されているため
    /// `meaning` まで含めて固定し、いずれかが書き換わったら検知できるようにする。
    func test_known_entries_match_specification() {
        let cases: [(Int, String, Gogyo, Shikigami.Kichi, String)] = [
            (0,  "貴人", .earth, .kichi, "高貴・援助・上位の力"),
            (1,  "騰蛇", .fire,  .kyo,   "変化・不安・口舌"),
            (2,  "朱雀", .fire,  .chu,   "文書・言語・知性"),
            (3,  "六合", .wood,  .kichi, "縁結び・協力・和合"),
            (4,  "勾陳", .earth, .kyo,   "停滞・土地・紛争"),
            (5,  "青龍", .wood,  .kichi, "財運・発展・吉祥"),
            (6,  "天空", .earth, .chu,   "虚偽・空白・迷い"),
            (7,  "白虎", .metal, .kyo,   "災難・争い・変動"),
            (8,  "太常", .earth, .kichi, "安定・礼儀・衣食"),
            (9,  "玄武", .water, .kyo,   "隠蔽・盗難・水難"),
            (10, "太陰", .metal, .chu,   "女性・隠れ・陰謀"),
            (11, "天后", .water, .kichi, "婚姻・母性・豊穣")
        ]
        for (id, name, gogyo, kichi, meaning) in cases {
            let s = Shikigami.from(index: id)
            XCTAssertEqual(s.nameJa, name, "name mismatch at id=\(id)")
            XCTAssertEqual(s.gogyo, gogyo, "gogyo mismatch at id=\(id)")
            XCTAssertEqual(s.kichi, kichi, "kichi mismatch at id=\(id)")
            XCTAssertEqual(s.meaning, meaning, "meaning mismatch at id=\(id)")
        }
    }

    /// `Meishiki.shikigami` が `shikigamiIndex` に応じて正しいエントリを返す。
    func test_meishiki_resolves_shikigami_by_index() {
        let m = SeimeiEngine.calc(year: 1990, month: 5, day: 15) // shikigamiIndex = 6 (天空)
        XCTAssertEqual(m.shikigamiIndex, 6)
        XCTAssertEqual(m.shikigami.nameJa, "天空")
        XCTAssertEqual(m.shikigami.gogyo, .earth)
    }
}
