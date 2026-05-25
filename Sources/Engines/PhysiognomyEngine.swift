import Foundation

/// 観相エンジン Slider 版（ENGINE B Slider）。
/// docs/design.md §3.2 の 6 パーツ重み付け合成に準拠。
public enum PhysiognomyEngine {
    public struct Input: Equatable, Sendable {
        public let eyebrow: Int
        public let eye: Int
        public let nose: Int
        public let mouth: Int
        public let ear: Int
        public let chin: Int

        public init(eyebrow: Int, eye: Int, nose: Int, mouth: Int, ear: Int, chin: Int) {
            self.eyebrow = eyebrow
            self.eye = eye
            self.nose = nose
            self.mouth = mouth
            self.ear = ear
            self.chin = chin
        }
    }

    public struct Result: Equatable, Sendable {
        public let score: Int
        public let templateId: String
    }

    public static func analyze(_ input: Input) -> Result {
        let eyebrow = clamped(input.eyebrow)
        let eye = clamped(input.eye)
        let nose = clamped(input.nose)
        let mouth = clamped(input.mouth)
        let ear = clamped(input.ear)
        let chin = clamped(input.chin)

        let total = 0.20 * Double(eyebrow)
            + 0.20 * Double(eye)
            + 0.18 * Double(nose)
            + 0.16 * Double(mouth)
            + 0.14 * Double(ear)
            + 0.12 * Double(chin)

        let score = Int(total.rounded())
        return Result(score: score, templateId: templateId(for: score))
    }

    public static func templateId(for score: Int) -> String {
        switch clamped(score) {
        case 0..<40:
            return "physiognomy.caution"
        case 40..<70:
            return "physiognomy.steady"
        default:
            return "physiognomy.flourish"
        }
    }

    private static func clamped(_ value: Int) -> Int {
        min(100, max(0, value))
    }
}
