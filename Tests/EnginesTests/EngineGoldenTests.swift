import XCTest
@testable import Engines

/// 既知入力 → 期待値の Golden テーブル。
/// docs/testing.md §2 「占術エンジンは決定論テスト必須」に準拠。
/// 期待値は docs/design.md §3.1 の式から手計算で導出している。
final class EngineGoldenTests: XCTestCase {

    private struct Case {
        let year: Int
        let month: Int
        let day: Int
        let expected: Meishiki
        let note: String
    }

    private let goldens: [Case] = [
        .init(
            year: 1990, month: 5, day: 15,
            expected: Meishiki(
                kanIndex: 6, shiIndex: 6, shikigamiIndex: 6,
                getsushoIndex: 4, gogyo: .metal, score: 60
            ),
            note: "代表的な平日。score がレンジ下限 60 に着地するケース"
        ),
        .init(
            year: 2000, month: 2, day: 29,
            expected: Meishiki(
                kanIndex: 6, shiIndex: 4, shikigamiIndex: 5,
                getsushoIndex: 1, gogyo: .metal, score: 99
            ),
            note: "うるう年 2/29。score がレンジ上限 99 に近いケース"
        ),
        .init(
            year: 1921, month: 2, day: 21,
            expected: Meishiki(
                kanIndex: 7, shiIndex: 9, shikigamiIndex: 9,
                getsushoIndex: 1, gogyo: .metal, score: 82
            ),
            note: "安倍晴明の伝承上の誕生日（docs/testing.md §2 で例示）"
        ),
        .init(
            year: 2024, month: 1, day: 1,
            expected: Meishiki(
                kanIndex: 0, shiIndex: 4, shikigamiIndex: 0,
                getsushoIndex: 0, gogyo: .wood, score: 72
            ),
            note: "月日境界 1/1。shikigami / getsusho ともに 0"
        ),
        .init(
            year: 2024, month: 12, day: 31,
            expected: Meishiki(
                kanIndex: 0, shiIndex: 4, shikigamiIndex: 5,
                getsushoIndex: 11, gogyo: .wood, score: 83
            ),
            note: "月日境界 12/31。getsusho が最大値 11"
        ),
        .init(
            year: 1900, month: 1, day: 1,
            expected: Meishiki(
                kanIndex: 6, shiIndex: 0, shikigamiIndex: 0,
                getsushoIndex: 0, gogyo: .metal, score: 84
            ),
            note: "プロパティテスト下限 1900 年・1/1"
        ),
        .init(
            year: 2100, month: 12, day: 31,
            expected: Meishiki(
                kanIndex: 6, shiIndex: 8, shikigamiIndex: 5,
                getsushoIndex: 11, gogyo: .metal, score: 95
            ),
            note: "プロパティテスト上限 2100 年・12/31"
        )
    ]

    func test_known_dates() {
        for c in goldens {
            let actual = SeimeiEngine.calc(year: c.year, month: c.month, day: c.day)
            XCTAssertEqual(
                actual, c.expected,
                """
                Golden mismatch for \(c.year)-\(c.month)-\(c.day) (\(c.note))
                  expected: \(c.expected)
                  actual:   \(actual)
                """
            )
        }
    }

    /// SeimeiEngine は純粋関数であり、同一入力に対して同一出力を返す（docs/architecture.md §2）。
    func test_deterministic_for_same_input() {
        let a = SeimeiEngine.calc(year: 1990, month: 5, day: 15)
        let b = SeimeiEngine.calc(year: 1990, month: 5, day: 15)
        XCTAssertEqual(a, b)
    }
}
