import Foundation

/// 命式（鑑定の基礎データ）。
/// docs/design.md §3.1 のシグネチャに準拠。
public struct Meishiki: Equatable, Sendable {
    public let kanIndex: Int        // 0..<10 十干
    public let shiIndex: Int        // 0..<12 十二支
    public let shikigamiIndex: Int  // 0..<12 十二天将
    public let getsushoIndex: Int   // 0..<12 月将
    public let gogyo: Gogyo
    public let score: Int           // 60..<100

    public init(
        kanIndex: Int,
        shiIndex: Int,
        shikigamiIndex: Int,
        getsushoIndex: Int,
        gogyo: Gogyo,
        score: Int
    ) {
        self.kanIndex = kanIndex
        self.shiIndex = shiIndex
        self.shikigamiIndex = shikigamiIndex
        self.getsushoIndex = getsushoIndex
        self.gogyo = gogyo
        self.score = score
    }

    public var shikigami: Shikigami { Shikigami.from(index: shikigamiIndex) }
}
