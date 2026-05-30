import Foundation
import SwiftData

// 全具体実装を組み立てる DI コンテナ
// テスト時はスタブに差し替える
struct AppDependencies {
    let claudeClient: ClaudeClient
    let authClient: SupabaseAuthClient
    let userRepo: UserRepository
    let fortuneRepo: FortuneRepository

    // local-first: ModelContainer を共有し LocalUserRepository / LocalFortuneRepository を注入する。
    // RevenueCat はアプリ起動時に一度だけ設定し、HomeViewModel.fetchTier() が
    // 未設定の Purchases.shared にアクセスしてクラッシュするのを防ぐ。
    static func live(modelContainer: ModelContainer) -> AppDependencies {
        if let apiKey = Bundle.main.infoDictionary?["REVENUECAT_PUBLIC_API_KEY"] as? String,
           !apiKey.isEmpty {
            RevenueCatManager.shared.configure(
                apiKey: apiKey,
                userId: persistentLocalUserId()
            )
        }

        return AppDependencies(
            claudeClient: LocalFortuneGenerator(),
            authClient: SupabaseAuthClient(),
            userRepo: LocalUserRepository(container: modelContainer),
            fortuneRepo: LocalFortuneRepository(container: modelContainer)
        )
    }

    static func stub() -> AppDependencies {
        AppDependencies(
            claudeClient: StubClaudeClient(),
            authClient: SupabaseAuthClient(),
            userRepo: StubUserRepository(),
            fortuneRepo: StubFortuneRepository()
        )
    }

    // UserDefaults に永続化した端末固有 UUID 文字列を返す（初回は新規生成）
    // OnboardingViewModel.stableLocalUserId() と同じ値を参照する
    private static func persistentLocalUserId() -> String {
        let key = "local_user_id"
        if let str = UserDefaults.standard.string(forKey: key) { return str }
        let id = UUID().uuidString
        UserDefaults.standard.set(id, forKey: key)
        return id
    }
}
