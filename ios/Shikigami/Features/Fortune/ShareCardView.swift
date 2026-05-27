import SwiftUI

// FR-NT-02: ImageRenderer でキャプチャする固定サイズのシェアカード
// アニメーションなし（静止画生成用）
struct ShareCardView: View {
    let fortune: Fortune
    let engine: FortuneEngine

    private static let cardSize: CGFloat = 1080

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.voidBlack, Color(hex: "#120D1A")],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(spacing: 0) {
                Spacer()

                // 上部: 五芒星 + キャラ名
                VStack(spacing: 20) {
                    PentagramView(size: 100)
                        .shadow(color: engine.accentColor.opacity(0.5), radius: 20)

                    Text(NSLocalizedString(engine.nameKey, comment: ""))
                        .font(.custom("YuMincho-Demibold", size: 52).weight(.semibold))
                        .tracking(10)
                        .foregroundStyle(engine.accentColor)
                }

                // 区切り
                Rectangle()
                    .fill(Color.oracleGold.opacity(0.3))
                    .frame(width: 200, height: 1)
                    .padding(.vertical, 44)

                // トピック
                HStack(spacing: 12) {
                    Text(fortune.topic.icon)
                        .font(.system(size: 22))
                    Text(fortune.topic.labelJa)
                        .font(.custom("HiraMinProN-W3", size: 22))
                        .tracking(4)
                }
                .foregroundStyle(fortune.topic.accentColor)

                // 鑑定文抜粋
                Text(excerpt)
                    .font(.custom("HiraMinProN-W3", size: 28))
                    .tracking(2)
                    .foregroundStyle(Color.white.opacity(0.88))
                    .multilineTextAlignment(.center)
                    .lineSpacing(14)
                    .padding(.horizontal, 100)
                    .padding(.top, 40)

                Spacer()

                // ブランディング
                VStack(spacing: 14) {
                    Rectangle()
                        .fill(Color.oracleGold.opacity(0.25))
                        .frame(width: 320, height: 1)

                    Text("式神鑑定")
                        .font(.custom("YuMincho-Medium", size: 28))
                        .tracking(8)
                        .foregroundStyle(Color.oracleGold.opacity(0.55))

                    // security.md §4.4 鑑定結果のシェア時にも責任表記を含める
                    Text("本鑑定は参考情報であり、結果を保証するものではありません。")
                        .font(.custom("HiraMinProN-W3", size: 16))
                        .tracking(1)
                        .foregroundStyle(Color.white.opacity(0.35))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 100)
                }
                .padding(.bottom, 80)
            }
        }
        .frame(width: Self.cardSize, height: Self.cardSize)
    }

    private var excerpt: String {
        let text = fortune.text
        guard text.count > 80 else { return text }
        return String(text.prefix(77)) + "…"
    }
}
