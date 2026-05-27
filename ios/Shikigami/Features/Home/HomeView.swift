import SwiftUI

struct HomeView: View {
    let deps: AppDependencies
    let user: AppUser

    @State private var vm: HomeViewModel
    @State private var showFortuneInput = false
    @State private var selectedEngine: FortuneEngine = .seimei

    init(deps: AppDependencies, user: AppUser) {
        self.deps = deps
        self.user = user
        _vm = State(initialValue: HomeViewModel(user: user, fortuneRepo: deps.fortuneRepo))
    }

    var body: some View {
        ZStack {
            StarfieldView()

            ScrollView {
                VStack(spacing: 32) {
                    headerSection
                    notificationSection
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
            FortuneInputView(deps: deps, user: user, engine: selectedEngine)
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

    // MARK: - 通知案内

    @ViewBuilder
    private var notificationSection: some View {
        if vm.dailyNotificationStatus.showsCard {
            DailyNotificationCard(status: vm.dailyNotificationStatus) {
                Task { await vm.enableDailyNotification() }
            }
            .fadeInUp()
        }
    }

    // MARK: - キャラクターカード

    private var characterSection: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                ForEach(FortuneEngine.allCases) { engine in
                    CharacterCardView(
                        engine: engine,
                        isSelected: selectedEngine == engine
                    ) {
                        selectedEngine = engine
                    }
                }
            }
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

struct DailyNotificationCard: View {
    let status: DailyNotificationStatus
    let action: () -> Void

    private var titleKey: String {
        switch status {
        case .denied:
            return "home.notification.denied.title"
        case .failed:
            return "home.notification.failed.title"
        case .unknown, .needsPermission, .scheduling, .scheduled:
            return "home.notification.title"
        }
    }

    private var messageKey: String {
        switch status {
        case .denied:
            return "home.notification.denied.message"
        case .failed:
            return "home.notification.failed.message"
        case .unknown, .needsPermission, .scheduling, .scheduled:
            return "home.notification.message"
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Color.oracleGold)
                .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 4) {
                Text(NSLocalizedString(titleKey, comment: ""))
                    .shikigamiFont(.label)
                    .foregroundStyle(Color.oracleGold)

                Text(NSLocalizedString(messageKey, comment: ""))
                    .shikigamiFont(.label)
                    .foregroundStyle(Color.white.opacity(0.65))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            if status.allowsRequest {
                Button(action: action) {
                    Text(NSLocalizedString("home.notification.cta", comment: ""))
                        .shikigamiFont(.label)
                        .foregroundStyle(Color.voidBlack)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.oracleGold)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            } else if status == .scheduling {
                ProgressView()
                    .tint(.oracleGold)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.oracleGold.opacity(0.25), lineWidth: 1)
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

struct CharacterCardView: View {
    let engine: FortuneEngine
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    if engine == .seimei {
                        PentagramView(size: 56)
                    } else {
                        Image(systemName: engine.symbolName)
                            .font(.system(size: 34, weight: .semibold))
                            .foregroundStyle(engine.accentColor)
                    }
                }
                .frame(width: 64, height: 64)

                VStack(alignment: .leading, spacing: 4) {
                    Text(NSLocalizedString(engine.nameKey, comment: ""))
                        .shikigamiFont(.heading)
                        .foregroundStyle(engine.accentColor)

                    Text(NSLocalizedString(engine.titleKey, comment: ""))
                        .shikigamiFont(.label)
                        .foregroundStyle(Color.white.opacity(0.6))
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? engine.accentColor : Color.white.opacity(0.28))
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(engine.accentColor.opacity(isSelected ? 0.7 : 0.25), lineWidth: isSelected ? 1.5 : 1)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(engine.accentColor.opacity(isSelected ? 0.08 : 0.03))
                    )
            )
            .shadow(color: engine.accentColor.opacity(isSelected ? 0.18 : 0.06), radius: 14)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}
