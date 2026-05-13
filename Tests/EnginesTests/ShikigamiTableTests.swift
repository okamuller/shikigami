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
    /// テーブルが変更された場合は意図した変更であることをレビューで確認する。
    func test_known_entries_match_specification() {
        let cases: [(Int, String, Gogyo, Shikigami.Kichi)] = [
            (0,  "貴人", .earth, .kichi),
            (1,  "騰蛇", .fire,  .kyo),
            (2,  "朱雀", .fire,  .chu),
            (3,  "六合", .wood,  .kichi),
            (4,  "勾陳", .earth, .kyo),
            (5,  "青龍", .wood,  .kichi),
            (6,  "天空", .earth, .chu),
            (7,  "白虎", .metal, .kyo),
            (8,  "太常", .earth, .kichi),
            (9,  "玄武", .water, .kyo),
            (10, "太陰", .metal, .chu),
            (11, "天后", .water, .kichi)
        ]
        for (id, name, gogyo, kichi) in cases {
            let s = Shikigami.from(index: id)
            XCTAssertEqual(s.nameJa, name, "name mismatch at id=\(id)")
            XCTAssertEqual(s.gogyo, gogyo, "gogyo mismatch at id=\(id)")
            XCTAssertEqual(s.kichi, kichi, "kichi mismatch at id=\(id)")
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
