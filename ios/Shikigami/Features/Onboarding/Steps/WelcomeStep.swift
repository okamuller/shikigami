import SwiftUI

struct WelcomeStep: View {
    let vm: OnboardingViewModel

    var body: some View {
        VStack(spacing: 48) {
            Spacer()

            PentagramView(size: 160, isSpinning: true)

            VStack(spacing: 12) {
                Text(NSLocalizedString("app.name", comment: ""))
                    .shikigamiFont(.display)
                    .foregroundStyle(Color.oracleGold)

                Text(NSLocalizedString("welcome.subtitle", comment: ""))
                    .shikigamiFont(.body)
                    .foregroundStyle(Color.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .fadeInUp()

            Spacer()

            VStack(spacing: 12) {
                CTAButton(title: NSLocalizedString("welcome.cta", comment: "")) {
                    vm.advance()
                }
                .disabled(vm.isLoading)

                if let error = vm.error {
                    Text(error)
                        .shikigamiFont(.label)
                        .foregroundStyle(Color.red.opacity(0.85))
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
    }
}

// MARK: - 共通 CTA ボタン

struct CTAButton: View {
    let title: String
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .shikigamiFont(.heading)
                .foregroundStyle(isEnabled ? Color.voidBlack : Color.white.opacity(0.3))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isEnabled ? Color.oracleGold : Color.white.opacity(0.1))
                )
        }
        .disabled(!isEnabled)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
    }
}
