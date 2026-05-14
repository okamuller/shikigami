import SwiftUI

struct GenderStep: View {
    @Binding var gender: Gender
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            VStack(spacing: 8) {
                Text(NSLocalizedString("onboarding.gender.title", comment: ""))
                    .shikigamiFont(.heading)
                    .foregroundStyle(Color.oracleGold)
            }
            .fadeInUp()

            HStack(spacing: 20) {
                GenderCard(
                    label: "陰",
                    sublabel: NSLocalizedString("gender.yin", comment: ""),
                    color: .fujiPurple,
                    isSelected: gender == .yin
                ) { gender = .yin }

                GenderCard(
                    label: "陽",
                    sublabel: NSLocalizedString("gender.yang", comment: ""),
                    color: .oracleGold,
                    isSelected: gender == .yang
                ) { gender = .yang }
            }
            .padding(.horizontal, 32)

            Button(NSLocalizedString("gender.none", comment: "")) {
                gender = .none
            }
            .shikigamiFont(.label)
            .foregroundStyle(Color.white.opacity(gender == .none ? 0.9 : 0.4))

            Spacer()

            CTAButton(
                title: NSLocalizedString("onboarding.next", comment: ""),
                isEnabled: true,
                action: onNext
            )
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
    }
}

private struct GenderCard: View {
    let label: String
    let sublabel: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Text(label)
                    .shikigamiFont(.display)
                    .foregroundStyle(color)

                Text(sublabel)
                    .shikigamiFont(.label)
                    .foregroundStyle(Color.white.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? color : Color.white.opacity(0.2), lineWidth: isSelected ? 2 : 1)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isSelected ? color.opacity(0.15) : Color.white.opacity(0.03))
                    )
            )
            .shadow(color: isSelected ? color.opacity(0.4) : .clear, radius: 8)
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}
