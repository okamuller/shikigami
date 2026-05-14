import SwiftUI

struct PaywallView: View {
    let partialText: String

    @State private var showPlanSelection = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            StarfieldView()

            VStack(spacing: 0) {
                // 閉じるボタン
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.white.opacity(0.4))
                            .font(.system(size: 28))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                Spacer()

                VStack(spacing: 28) {
                    PentagramView(size: 90)
                        .pulsate()

                    // ブラー部分（ペイウォール）
                    VStack(spacing: 8) {
                        Text(NSLocalizedString("paywall.teaser.preview", comment: ""))
                            .shikigamiFont(.body)
                            .foregroundStyle(Color.white.opacity(0.85))
                            .multilineTextAlignment(.center)

                        if !partialText.isEmpty {
                            Text(partialText)
                                .shikigamiFont(.body)
                                .foregroundStyle(Color.white.opacity(0.85))
                                .blur(radius: 8)
                        } else {
                            Text(NSLocalizedString("paywall.blurred.placeholder", comment: ""))
                                .shikigamiFont(.body)
                                .foregroundStyle(Color.white.opacity(0.85))
                                .blur(radius: 8)
                        }
                    }
                    .padding(.horizontal, 32)

                    Text(NSLocalizedString("paywall.headline", comment: ""))
                        .shikigamiFont(.heading)
                        .foregroundStyle(Color.oracleGold)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .fadeInUp()
                }

                Spacer()

                VStack(spacing: 12) {
                    CTAButton(title: NSLocalizedString("paywall.cta", comment: "")) {
                        showPlanSelection = true
                    }
                    .padding(.horizontal, 32)

                    Text(NSLocalizedString("paywall.trial", comment: ""))
                        .shikigamiFont(.label)
                        .foregroundStyle(Color.white.opacity(0.5))
                }
                .padding(.bottom, 48)
            }
        }
        .sheet(isPresented: $showPlanSelection) {
            PlanSelectionView()
        }
    }
}
