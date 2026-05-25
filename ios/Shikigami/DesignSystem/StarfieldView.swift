import SwiftUI

// 星空背景ビュー（Canvas ベース、twinkle アニメ付き）
struct StarfieldView: View {
    private struct Star: Identifiable {
        let id: Int
        let x: CGFloat
        let y: CGFloat
        let radius: CGFloat
        let duration: Double
        let baseOpacity: Double
    }

    private let stars: [Star]

    init(count: Int = 80, seed: Int = 42) {
        var gen = SeededRNG(seed: UInt64(bitPattern: Int64(seed)))
        stars = (0..<count).map { i in
            Star(
                id: i,
                x: gen.nextDouble(),
                y: gen.nextDouble(),
                radius: 1 + gen.nextDouble() * 2,
                duration: 2 + Double(gen.nextDouble()) * 3,
                baseOpacity: 0.3 + gen.nextDouble() * 0.7
            )
        }
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.voidBlack.ignoresSafeArea()
                ForEach(stars) { star in
                    Circle()
                        .fill(Color.white)
                        .frame(width: star.radius * 2, height: star.radius * 2)
                        .position(
                            x: star.x * geo.size.width,
                            y: star.y * geo.size.height
                        )
                        .modifier(TwinkleModifier(
                            duration: star.duration,
                            baseOpacity: star.baseOpacity
                        ))
                }
            }
        }
        .ignoresSafeArea()
    }
}

private struct TwinkleModifier: ViewModifier {
    let duration: Double
    let baseOpacity: Double
    @State private var opacity: Double

    init(duration: Double, baseOpacity: Double) {
        self.duration = duration
        self.baseOpacity = baseOpacity
        _opacity = State(initialValue: baseOpacity)
    }

    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: duration).repeatForever(autoreverses: true)
                ) {
                    opacity = baseOpacity < 0.7 ? 1.0 : 0.3
                }
            }
    }
}

// 再現性のある疑似乱数生成（xorshift64）
private struct SeededRNG {
    private var state: UInt64

    init(seed: UInt64) { state = seed == 0 ? 1 : seed }

    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }

    mutating func nextDouble() -> CGFloat {
        CGFloat(next() & 0xFFFF_FFFF) / CGFloat(0xFFFF_FFFF)
    }
}
