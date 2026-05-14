import Foundation

// 全具体実装を組み立てる DI コンテナ
// テスト時はスタブに差し替える
struct AppDependencies {
    let claudeClient: ClaudeClient
    let authClient: SupabaseAuthClient
    let userRepo: UserRepository
    let fortuneRepo: FortuneRepository

    static func live() -> AppDependencies {
        let auth = SupabaseAuthClient()
        let base = SupabaseConfig.url

        let jwtProvider: @Sendable () async throws -> String = {
            try await auth.currentJWT()
        }

        return AppDependencies(
            claudeClient: SupabaseClaudeClient(baseURL: base, jwtProvider: jwtProvider),
            authClient: auth,
            userRepo: SupabaseUserRepository(baseURL: base, jwtProvider: jwtProvider),
            fortuneRepo: SupabaseFortuneRepository(baseURL: base, jwtProvider: jwtProvider)
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
