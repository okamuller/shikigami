// D_screens.md アニメーション仕様準拠
import SwiftUI

// MARK: - spinSlow: 20秒で1回転（ローディング・五芒星）

struct SpinSlowModifier: ViewModifier {
    @State private var angle: Double = 0

    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(angle))
            .onAppear {
                withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                    angle = 360
                }
            }
    }
}

// MARK: - floatY: 4秒で上下8pt浮遊（キャラアイコン）

struct FloatYModifier: ViewModifier {
    @State private var offsetY: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .offset(y: offsetY)
            .onAppear {
                withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                    offsetY = -8
                }
            }
    }
}

// MARK: - fadeInUp: 0.4秒フェードイン＋上方向スライド（画面遷移・結果表示）

struct FadeInUpModifier: ViewModifier {
    @State private var opacity: Double = 0
    @State private var offsetY: CGFloat = 20

    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .offset(y: offsetY)
            .onAppear {
                withAnimation(.easeOut(duration: 0.4)) {
                    opacity = 1
                    offsetY = 0
                }
            }
    }
}

// MARK: - pulsate: 2秒グロー点滅（契約成立・強調要素）

struct PulsateModifier: ViewModifier {
    @State private var glowOpacity: Double = 0.4

    func body(content: Content) -> some View {
        content
            .shadow(color: Color.oracleGold.opacity(glowOpacity), radius: 12)
            .onAppear {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    glowOpacity = 1.0
                }
            }
    }
}

// MARK: - View extension

extension View {
    func spinSlow()  -> some View { modifier(SpinSlowModifier()) }
    func floatY()    -> some View { modifier(FloatYModifier()) }
    func fadeInUp()  -> some View { modifier(FadeInUpModifier()) }
    func pulsate()   -> some View { modifier(PulsateModifier()) }
}
