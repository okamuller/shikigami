import SwiftUI

struct BirthDateStep: View {
    @Binding var birthDate: Date
    let onNext: () -> Void

    @State private var hasChanged = false

    private static let minDate = Calendar.current.date(from: DateComponents(year: 1900, month: 1, day: 1))!
    private static let maxDate = Date.now

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 8) {
                Text(NSLocalizedString("onboarding.birthdate.title", comment: ""))
                    .shikigamiFont(.heading)
                    .foregroundStyle(Color.oracleGold)

                Text(NSLocalizedString("onboarding.birthdate.subtitle", comment: ""))
                    .shikigamiFont(.label)
                    .foregroundStyle(Color.white.opacity(0.6))
            }
            .fadeInUp()

            DatePicker(
                "",
                selection: Binding(
                    get: { birthDate },
                    set: { birthDate = $0; hasChanged = true }
                ),
                in: Self.minDate...Self.maxDate,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .colorScheme(.dark)
            .accentColor(.oracleGold)
            .padding(.horizontal, 16)

            Spacer()

            CTAButton(
                title: NSLocalizedString("onboarding.next", comment: ""),
                isEnabled: hasChanged,
                action: onNext
            )
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
    }
}
