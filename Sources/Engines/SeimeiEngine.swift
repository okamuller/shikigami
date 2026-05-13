import Foundation

/// 六壬神課エンジン（ENGINE A）。
/// docs/design.md §3.1 / .claude/B_logic.md「ENGINE A」の式を Swift に移植した純粋関数。
public enum SeimeiEngine {

    /// 十干 → 五行 の対応表。
    /// 0,1=木 / 2,3=火 / 4,5=土 / 6,7=金 / 8,9=水
    static let gogyoTable: [Gogyo] = [
        .wood, .wood, .fire, .fire, .earth,
        .earth, .metal, .metal, .water, .water
    ]

    /// 生年月日から命式を計算する。副作用なし・スレッドセーフ。
    public static func calc(year: Int, month: Int, day: Int) -> Meishiki {
        let kan       = ((year - 4) % 10 + 10) % 10
        let shi       = ((year - 4) % 12 + 12) % 12
        let shikigami = ((month + day - 2) % 12 + 12) % 12
        let getsusho  = ((month - 1) % 12 + 12) % 12
        let score     = ((year * 7 + month * 31 + day * 13) % 40) + 60
        return Meishiki(
            kanIndex: kan,
            shiIndex: shi,
            shikigamiIndex: shikigami,
            getsushoIndex: getsusho,
            gogyo: gogyoTable[kan],
            score: score
        )
    }
}
