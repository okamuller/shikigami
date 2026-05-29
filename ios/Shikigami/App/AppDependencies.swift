import Foundation
import SwiftData

// 全具体実装を組み立てる DI コンテナ
// テスト時はスタブに差し替える
struct AppDependencies {
    let claudeClient: ClaudeClient
    let authClient: SupabaseAuthClient
    let userRepo: UserRepository
    let fortuneRepo: FortuneRepository

    // local-first: ModelContainer を共有し LocalUserRepository / LocalFortuneRepository を注入する
    static func live(modelContainer: ModelContainer) -> AppDependencies {
        let context = ModelContext(modelContainer)
        return AppDependencies(
            claudeClient: LocalFortuneGenerator(),
            authClient: SupabaseAuthClient(),
            userRepo: LocalUserRepository(context: context),
            fortuneRepo: LocalFortuneRepository(context: context)
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
}
