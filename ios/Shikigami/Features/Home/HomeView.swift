import SwiftUI

struct HomeView: View {
    let deps: AppDependencies
    let user: AppUser

    @State private var vm: HomeViewModel
    @State private var showFortuneInput = false

    init(deps: AppDependencies, user: AppUser) {
        self.deps = deps
        self.user = user
        _vm = State(initialValue: HomeViewModel(fortuneRepo: deps.fortuneRepo))
    }

    var body: some View {
        ZStack {
            StarfieldView()

            ScrollView {
                VStack(spacing: 32) {
                    headerSection
                    characterSection
                    historySection
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                .padding(.bottom, 40)
            }
        }
        .task { await vm.onAppear() }
        .sheet(isPresented: $showFortuneInput) {
            FortuneInputView(deps: deps, user: user)
        }
    }

    // MARK: - ヘッダー（今日の鑑定）

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("home.todayFortune", comment: ""))
                .shikigamiFont(.label)
                .foregroundStyle(Color.white.opacity(0.6))

            if let fortune = vm.todayFortune {
                FortunePreviewCard(fortune: fortune)
            } else {
                Text(NSLocalizedString("home.noFortune", comment: ""))
                    .shikigamiFont(.body)
                    .foregroundStyle(Color.white.opacity(0.5))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            }
        }
        .fadeInUp()
    }

    // MARK: - キャラクターカード（晴明）

    private var characterSection: some View {
        VStack(spacing: 20) {
            CharacterCardView(character: .seimei)
                .floatY()

            CTAButton(title: NSLocalizedString("home.startFortune", comment: "")) {
                showFortuneInput = true
            }
        }
    }

    // MARK: - 履歴リスト

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !vm.recentHistory.isEmpty {
                Text(NSLocalizedString("home.recentHistory", comment: ""))
                    .shikigamiFont(.label)
                    .foregroundStyle(Color.white.opacity(0.6))

                ForEach(vm.recentHistory) { fortune in
                    FortuneHistoryRow(fortune: fortune)
                }
            }
        }
    }
}

// MARK: - サブビュー

struct FortunePreviewCard: View {
    let fortune: Fortune

    var body: some View {
        Text(fortune.text.prefix(60) + "…")
            .shikigamiFont(.body)
            .foregroundStyle(Color.white.opacity(0.85))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.oracleGold.opacity(0.3), lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.04))
                    )
            )
    }
}

struct FortuneHistoryRow: View {
    let fortune: Fortune

    var body: some View {
        HStack {
            Text(fortune.topic.icon)
                .font(.system(size: 20))

            VStack(alignment: .leading, spacing: 2) {
                Text(fortune.topic.labelJa)
                    .shikigamiFont(.label)
                    .foregroundStyle(fortune.topic.accentColor)
                Text(fortune.text.prefix(30) + "…")
                    .shikigamiFont(.label)
                    .foregroundStyle(Color.white.opacity(0.6))
            }
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.04))
        )
    }
}

enum Character { case seimei }

struct CharacterCardView: View {
    let character: Character

    var body: some View {
        VStack(spacing: 16) {
            PentagramView(size: 80)

            VStack(spacing: 4) {
                Text(NSLocalizedString("character.seimei.name", comment: ""))
                    .shikigamiFont(.heading)
                    .foregroundStyle(Color.oracleGold)

                Text(NSLocalizedString("character.seimei.title", comment: ""))
                    .shikigamiFont(.label)
                    .foregroundStyle(Color.white.opacity(0.6))
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.oracleGold.opacity(0.5), lineWidth: 1.5)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.03))
                )
        )
        .shadow(color: Color.oracleGold.opacity(0.15), radius: 16)
    }
}
