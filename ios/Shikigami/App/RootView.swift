import SwiftUI

enum AppRoute {
    case onboarding
    case main(AppUser)
}

struct RootView: View {
    let deps: AppDependencies
    @State private var route: AppRoute = .onboarding

    var body: some View {
        Group {
            switch route {
            case .onboarding:
                OnboardingFlow(deps: deps, onComplete: { user in
                    route = .main(user)
                })
            case .main(let user):
                MainTabView(deps: deps, user: user, onDeleted: { route = .onboarding })
            }
        }
        .task {
            // セッションが既にある場合はオンボーディングをスキップ
            for await session in deps.authClient.sessionStream {
                if session != nil {
                    if let user = try? await deps.userRepo.fetchUser(),
                       user.birthDate != nil {
                        route = .main(user)
                    }
                    return
                }
            }
        }
    }
}

// MARK: - メインタブ（Phase 1 は Home タブのみ）

struct MainTabView: View {
    let deps: AppDependencies
    let user: AppUser
    let onDeleted: () -> Void

    var body: some View {
        TabView {
            HomeView(deps: deps, user: user)
                .tabItem {
                    Label(NSLocalizedString("tab.home", comment: ""), systemImage: "star.fill")
                }

            PhysiognomyInputView()
                .tabItem {
                    Label(NSLocalizedString("tab.physiognomy", comment: ""), systemImage: "face.smiling")
                }

            SettingsView(deps: deps, onDeleted: onDeleted)
                .tabItem {
                    Label(NSLocalizedString("tab.settings", comment: ""), systemImage: "gearshape.fill")
                }
        }
        .tint(.oracleGold)
    }
}
