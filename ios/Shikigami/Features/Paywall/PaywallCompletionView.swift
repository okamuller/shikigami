import SwiftUI

struct PaywallCompletionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var appeared = false

    var body: some View {
        ZStack {
            StarfieldView()

            VStack(spacing: 40) {
                Spacer()

                PentagramView(size: 140)
                    .pulsate()
                    .scaleEffect(appeared ? 1 : 0.5)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: appeared)

                VStack(spacing: 12) {
                    Text(NSLocalizedString("paywall.completion.title", comment: ""))
                        .shikigamiFont(.display)
                        .foregroundStyle(Color.oracleGold)
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeIn(duration: 0.5).delay(0.4), value: appeared)

                    Text(NSLocalizedString("paywall.completion.subtitle", comment: ""))
                        .shikigamiFont(.body)
                        .foregroundStyle(Color.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeIn(duration: 0.5).delay(0.6), value: appeared)
                }
                .padding(.horizontal, 32)

                // 解放機能リスト
                VStack(alignment: .leading, spacing: 10) {
                    ForEach([
                        NSLocalizedString("paywall.completion.feature1", comment: ""),
                        NSLocalizedString("paywall.completion.feature2", comment: ""),
                        NSLocalizedString("paywall.completion.feature3", comment: ""),
                    ], id: \.self) { feature in
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Color.oracleGold)
                            Text(feature)
                                .shikigamiFont(.label)
                                .foregroundStyle(Color.white.opacity(0.8))
                        }
                    }
                }
                .opacity(appeared ? 1 : 0)
                .animation(.easeIn(duration: 0.5).delay(0.8), value: appeared)

                Spacer()

                CTAButton(title: NSLocalizedString("paywall.completion.cta", comment: "")) {
                    dismiss()
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
                .opacity(appeared ? 1 : 0)
                .animation(.easeIn(duration: 0.5).delay(1.0), value: appeared)
            }
        }
        .onAppear { appeared = true }
    }
}
