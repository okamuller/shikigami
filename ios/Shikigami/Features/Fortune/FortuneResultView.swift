import SwiftUI

struct FortuneResultView: View {
    let fortune: Fortune
    let engine: FortuneEngine
    let deps: AppDependencies
    let tier: SubscriptionTier

    @State private var displayedChars = 0
    @State private var showPaywall = false
    @State private var shareImage: UIImage?
    @State private var showShareSheet = false
    @Environment(\.dismiss) private var dismiss

    private var fullText: String { fortune.text }

    var body: some View {
        ZStack {
            StarfieldView()

            VStack(spacing: 0) {
                // ヘッダー
                HStack {
                    Button(action: renderAndShare) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(Color.oracleGold.opacity(0.8))
                            .font(.system(size: 20))
                    }
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.white.opacity(0.4))
                            .font(.system(size: 24))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                ScrollView {
                    VStack(spacing: 32) {
                        // 式神シンボル
                        PentagramView(size: 80)
                            .pulsate()

                        // 鑑定文（タイプライター演出）
                        VStack(spacing: 16) {
                            let displayed = String(fullText.prefix(displayedChars))
                            Text(displayed)
                                .shikigamiFont(.body)
                                .foregroundStyle(Color.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                                .lineSpacing(8)

                            // フォールバック通知
                            if fortune.isFallback {
                                Text(NSLocalizedString("fortune.result.fallback", comment: ""))
                                    .shikigamiFont(.label)
                                    .foregroundStyle(Color.oracleGold.opacity(0.6))
                                    .padding(.top, 4)
                            }
                        }
                        .padding(.horizontal, 28)
                        .fadeInUp()

                        // FREE ユーザー向けペイウォールティーザー
                        if tier == .free {
                            PaywallTeaserView {
                                showPaywall = true
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.top, 24)
                    .padding(.bottom, 48)
                }
            }
        }
        .task {
            // タイプライター演出
            for i in 1...max(1, fullText.count) {
                try? await Task.sleep(nanoseconds: 60_000_000)
                displayedChars = i
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(partialText: String(fullText.suffix(40)))
        }
        .sheet(isPresented: $showShareSheet) {
            if let img = shareImage {
                ShareSheet(items: [img])
            }
        }
    }

    private func renderAndShare() {
        let card = ShareCardView(fortune: fortune, engine: engine)
        let renderer = ImageRenderer(content: card)
        renderer.scale = UIScreen.main.scale
        shareImage = renderer.uiImage
        showShareSheet = true
    }
}

// MARK: - ブラーペイウォールティーザー

struct PaywallTeaserView: View {
    let onTap: () -> Void

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // ブラーがかかる領域
                Text("天命の深き意味、汝の運命の詳細を解き明かさん。式神の言葉、まだ続くなり...")
                    .shikigamiFont(.body)
                    .foregroundStyle(Color.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .blur(radius: 6)
                    .padding(.bottom, 12)

                // CTA
                Button(action: onTap) {
                    Text(NSLocalizedString("paywall.teaser.cta", comment: ""))
                        .shikigamiFont(.heading)
                        .foregroundStyle(Color.voidBlack)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.oracleGold)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .pulsate()
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.voidBlack.opacity(0.8))
                    .stroke(Color.oracleGold.opacity(0.4), lineWidth: 1)
            )
        }
    }
}
