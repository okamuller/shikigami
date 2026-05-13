import XCTest
@testable import Engines

/// プロパティテスト（不変条件）。
/// docs/testing.md §2「プロパティテスト」/ docs/design.md §3.1「テスト観点」に準拠。
final class EnginePropertyTests: XCTestCase {

    /// 任意の (year ∈ 1900..2100, month ∈ 1..12, day ∈ 1..28) に対して
    /// すべてのインデックスとスコアが規定レンジに収まる。
    func test_indices_and_score_are_in_range() {
        for year in stride(from: 1900, through: 2100, by: 7) {
            for month in 1...12 {
                for day in [1, 7, 14, 21, 28] {
                    let m = SeimeiEngine.calc(year: year, month: month, day: day)
                    XCTAssertTrue((0..<10).contains(m.kanIndex),
                                  "kanIndex out of range for \(year)-\(month)-\(day): \(m.kanIndex)")
                    XCTAssertTrue((0..<12).contains(m.shiIndex),
                                  "shiIndex out of range for \(year)-\(month)-\(day): \(m.shiIndex)")
                    XCTAssertTrue((0..<12).contains(m.shikigamiIndex),
                                  "shikigamiIndex out of range for \(year)-\(month)-\(day): \(m.shikigamiIndex)")
                    XCTAssertTrue((0..<12).contains(m.getsushoIndex),
                                  "getsushoIndex out of range for \(year)-\(month)-\(day): \(m.getsushoIndex)")
                    XCTAssertTrue((60..<100).contains(m.score),
                                  "score out of [60,100) for \(year)-\(month)-\(day): \(m.score)")
                }
            }
        }
    }

    /// gogyo は十干（kanIndex）にのみ依存し、`gogyoTable` の写像と一致する。
    func test_gogyo_follows_kanIndex() {
        let expected: [Gogyo] = [
            .wood, .wood, .fire, .fire, .earth,
            .earth, .metal, .metal, .water, .water
        ]
        for year in stride(from: 1900, through: 2100, by: 3) {
            let m = SeimeiEngine.calc(year: year, month: 6, day: 15)
            XCTAssertEqual(m.gogyo, expected[m.kanIndex],
                           "gogyo mismatch for year \(year): kan=\(m.kanIndex) gogyo=\(m.gogyo)")
        }
    }

    /// 月将（getsushoIndex）は `month - 1` と一致する。
    func test_getsusho_equals_month_minus_one() {
        for month in 1...12 {
            let m = SeimeiEngine.calc(year: 2000, month: month, day: 10)
            XCTAssertEqual(m.getsushoIndex, month - 1,
                           "getsushoIndex should be month-1 for month \(month)")
        }
    }

    /// 式神（shikigamiIndex）は (month + day) のみに依存し、年に依存しない。
    func test_shikigami_depends_only_on_month_and_day() {
        for month in 1...12 {
            for day in [1, 10, 20, 28] {
                let a = SeimeiEngine.calc(year: 1950, month: month, day: day).shikigamiIndex
                let b = SeimeiEngine.calc(year: 2050, month: month, day: day).shikigamiIndex
                XCTAssertEqual(a, b,
                               "shikigamiIndex should not depend on year for \(month)/\(day)")
            }
        }
    }
}
