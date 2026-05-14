import SwiftUI

struct TopicStep: View {
    @Binding var topic: Topic?
    let onNext: () -> Void

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 8) {
                Text(NSLocalizedString("onboarding.topic.title", comment: ""))
                    .shikigamiFont(.heading)
                    .foregroundStyle(Color.oracleGold)

                Text(NSLocalizedString("onboarding.topic.subtitle", comment: ""))
                    .shikigamiFont(.label)
                    .foregroundStyle(Color.white.opacity(0.6))
            }
            .fadeInUp()

            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(Topic.allCases) { t in
                    TopicCard(topic: t, isSelected: topic == t) {
                        topic = t
                    }
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            CTAButton(
                title: NSLocalizedString("onboarding.next", comment: ""),
                isEnabled: topic != nil,
                action: onNext
            )
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
    }
}

private struct TopicCard: View {
    let topic: Topic
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(topic.icon)
                    .font(.system(size: 28))

                Text(topic.labelJa)
                    .shikigamiFont(.label)
                    .foregroundStyle(Color.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? topic.accentColor : Color.white.opacity(0.15), lineWidth: isSelected ? 2 : 1)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isSelected ? topic.accentColor.opacity(0.2) : Color.white.opacity(0.04))
                    )
            )
        }
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}
