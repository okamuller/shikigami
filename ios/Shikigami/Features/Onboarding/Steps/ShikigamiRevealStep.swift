import SwiftUI

struct ShikigamiRevealStep: View {
    let vm: OnboardingViewModel
    let onComplete: (AppUser) -> Void

    // 十干・十二支 表示名
    private static let kanNames  = ["甲","乙","丙","丁","戊","己","庚","辛","壬","癸"]
    private static let shiNames  = ["子","丑","寅","卯","辰","巳","午","未","申","酉","戌","亥"]
    private static let gogyoJa: [String: String] = [
        "wood": "木", "fire": "火", "earth": "土", "metal": "金", "water": "水",
    ]

    @State private var phase: RevealPhase = .loading
    @State private var shownChars = 0
    @State private var isCompletingSignup = false

    private enum RevealPhase { case loading, revealed }

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            switch phase {
            case .loading:
                PentagramView(size: 140, isSpinning: true)
                    .scaleEffect(1.2)

                Text(NSLocalizedString("reveal.calculating", comment: ""))
                    .shikigamiFont(.body)
                    .foregroundStyle(Color.white.opacity(0.7))
                    .fadeInUp()

            case .revealed:
                if let m = vm.meishiki {
                    revealedContent(m)
                }
            }

            Spacer()

            if phase == .revealed {
                CTAButton(
                    title: NSLocalizedString("reveal.cta", comment: ""),
                    isEnabled: !isCompletingSignup,
                    action: {
                        Task { await completeSignup() }
                    }
                )
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
                .fadeInUp()
            }
        }
        .task {
            vm.calculateMeishiki()
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            withAnimation { phase = .revealed }
            await animateChars()
        }
    }

    @ViewBuilder
    private func revealedContent(_ m: Meishiki) -> some View {
        let shikigami = Shikigami.from(index: m.shikigamiIndex)
        let kanName  = Self.kanNames[m.kanIndex]
        let shiName  = Self.shiNames[m.shiIndex]
        let gogyoJa  = Self.gogyoJa[m.gogyo.rawValue] ?? "木"
        let fullName = shikigami.nameJa

        VStack(spacing: 24) {
            PentagramView(size: 100)
                .pulsate()

            VStack(spacing: 8) {
                Text(NSLocalizedString("reveal.yourShikigami", comment: ""))
                    .shikigamiFont(.label)
                    .foregroundStyle(Color.white.opacity(0.6))

                // タイプライター演出
                let displayed = String(fullName.prefix(shownChars))
                Text(displayed)
                    .shikigamiFont(.display)
                    .foregroundStyle(Color.oracleGold)
                    .shadow(color: Color.oracleGold.opacity(0.5), radius: 8)
            }

            HStack(spacing: 24) {
                ShikigamiInfoBadge(label: NSLocalizedString("reveal.kanshi", comment: ""), value: "\(kanName)\(shiName)")
                ShikigamiInfoBadge(label: NSLocalizedString("reveal.gogyo", comment: ""), value: gogyoJa)
                ShikigamiInfoBadge(label: NSLocalizedString("reveal.kichi", comment: ""), value: shikigami.kichi.rawValue)
            }

            Text(shikigami.meaning)
                .shikigamiFont(.body)
                .foregroundStyle(Color.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .fadeInUp()
        }
    }

    private func animateChars() async {
        guard let m = vm.meishiki else { return }
        let name = Shikigami.from(index: m.shikigamiIndex).nameJa
        for i in 1...name.count {
            try? await Task.sleep(nanoseconds: 80_000_000)
            shownChars = i
        }
    }

    private func completeSignup() async {
        isCompletingSignup = true
        if let user = await vm.completeOnboarding() {
            onComplete(user)
        }
        isCompletingSignup = false
    }
}

private struct ShikigamiInfoBadge: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .shikigamiFont(.label)
                .foregroundStyle(Color.white.opacity(0.5))
            Text(value)
                .shikigamiFont(.body)
                .foregroundStyle(Color.oracleGold)
        }
    }
}
