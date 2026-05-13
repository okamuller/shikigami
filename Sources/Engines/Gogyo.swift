import Foundation

/// 五行（木火土金水）。
/// docs/design.md §3.1 ENGINE A — 六壬神課（Swift）
public enum Gogyo: String, CaseIterable, Equatable, Sendable {
    case wood, fire, earth, metal, water
}
