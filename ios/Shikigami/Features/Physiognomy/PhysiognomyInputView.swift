import SwiftUI

struct PhysiognomyInputView: View {
    @State private var input = PhysiognomySliderState()

    private var result: PhysiognomyEngine.Result {
        PhysiognomyEngine.analyze(input.engineInput)
    }

    var body: some View {
        ZStack {
            StarfieldView()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    sliderSection
                    resultSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                .padding(.bottom, 40)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(NSLocalizedString("physiognomy.title", comment: ""))
                .shikigamiFont(.heading)
                .foregroundStyle(Color.jadeGreen)

            Text(NSLocalizedString("physiognomy.subtitle", comment: ""))
                .shikigamiFont(.body)
                .foregroundStyle(Color.white.opacity(0.68))
        }
        .fadeInUp()
    }

    private var sliderSection: some View {
        VStack(spacing: 16) {
            PhysiognomySliderRow(titleKey: "physiognomy.eyebrow", value: $input.eyebrow)
            PhysiognomySliderRow(titleKey: "physiognomy.eye", value: $input.eye)
            PhysiognomySliderRow(titleKey: "physiognomy.nose", value: $input.nose)
            PhysiognomySliderRow(titleKey: "physiognomy.mouth", value: $input.mouth)
            PhysiognomySliderRow(titleKey: "physiognomy.ear", value: $input.ear)
            PhysiognomySliderRow(titleKey: "physiognomy.chin", value: $input.chin)
        }
    }

    private var resultSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text(NSLocalizedString("physiognomy.score", comment: ""))
                    .shikigamiFont(.label)
                    .foregroundStyle(Color.white.opacity(0.62))
                Spacer()
                Text("\(result.score)")
                    .font(.system(size: 42, weight: .semibold, design: .serif))
                    .foregroundStyle(Color.jadeGreen)
                Text("/100")
                    .shikigamiFont(.label)
                    .foregroundStyle(Color.white.opacity(0.45))
            }

            Text(NSLocalizedString(result.templateId, comment: ""))
                .shikigamiFont(.body)
                .foregroundStyle(Color.white.opacity(0.86))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.jadeGreen.opacity(0.42), lineWidth: 1)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.jadeGreen.opacity(0.08))
                )
        )
        .shadow(color: Color.jadeGreen.opacity(0.12), radius: 16)
    }
}

private struct PhysiognomySliderState {
    var eyebrow = 50.0
    var eye = 50.0
    var nose = 50.0
    var mouth = 50.0
    var ear = 50.0
    var chin = 50.0

    var engineInput: PhysiognomyEngine.Input {
        .init(
            eyebrow: Int(eyebrow.rounded()),
            eye: Int(eye.rounded()),
            nose: Int(nose.rounded()),
            mouth: Int(mouth.rounded()),
            ear: Int(ear.rounded()),
            chin: Int(chin.rounded())
        )
    }
}

private struct PhysiognomySliderRow: View {
    let titleKey: String
    @Binding var value: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(NSLocalizedString(titleKey, comment: ""))
                    .shikigamiFont(.label)
                    .foregroundStyle(Color.white.opacity(0.72))
                Spacer()
                Text("\(Int(value.rounded()))")
                    .monospacedDigit()
                    .shikigamiFont(.label)
                    .foregroundStyle(Color.jadeGreen)
            }

            Slider(value: $value, in: 0...100, step: 1)
                .tint(.jadeGreen)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.05))
        )
    }
}
