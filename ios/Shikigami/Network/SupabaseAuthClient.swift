import Foundation
import AuthenticationServices
#if canImport(Supabase)
import Supabase
#endif

// Supabase Auth ラッパー
// supabase-swift SDK（github.com/supabase/supabase-swift ~> 2.0）を使用
// 実際の Supabase クライアントは SupabaseClient 型を想定
// NOTE: Xcode プロジェクトに supabase-swift を追加後、import Supabase のコメントを外すこと

// import Supabase  ← Xcode 側で有効化

final class SupabaseAuthClient {
    // MARK: - State

    private(set) var currentSession: SessionData?
    private var sessionContinuations: [AsyncStream<SessionData?>.Continuation] = []
#if canImport(Supabase)
    private let supabase: SupabaseClient

    init(supabase: SupabaseClient = SupabaseClient(
        supabaseURL: SupabaseConfig.url,
        supabaseKey: SupabaseConfig.anonKey
    )) {
        self.supabase = supabase
    }
#else
    init() {}
#endif

    // MARK: - Apple Sign In

    /// Apple Sign In JWT + nonce を使って Supabase Auth にサインイン
    /// Xcode プロジェクトでは supabase.auth.signInWithIdToken を呼び出す
    func signInWithApple(idToken: String, nonce: String) async throws {
#if canImport(Supabase)
        let session = try await supabase.auth.signInWithIdToken(
            credentials: .init(provider: .apple, idToken: idToken, nonce: nonce)
        )
        let sessionData = SessionData(userId: session.user.id.uuidString, jwt: session.accessToken)
        currentSession = sessionData
        notifySessionChange(sessionData)
#else
        // SDK 未リンク時の SwiftUI プレビュー / スタブ実行用。
        let mockSession = SessionData(userId: UUID().uuidString, jwt: idToken)
        currentSession = mockSession
        notifySessionChange(mockSession)
#endif
    }

    func signOut() async throws {
#if canImport(Supabase)
        try await supabase.auth.signOut()
#endif
        currentSession = nil
        notifySessionChange(nil)
    }

    /// セッション変化の AsyncStream（RootView で購読）
    var sessionStream: AsyncStream<SessionData?> {
        AsyncStream { continuation in
            sessionContinuations.append(continuation)
            continuation.yield(currentSession)
        }
    }

    /// Edge Function 呼び出し用 JWT を返す
    func currentJWT() async throws -> String {
        if let session = currentSession {
            return session.jwt
        }
#if canImport(Supabase)
        let session = try await supabase.auth.session
        let sessionData = SessionData(userId: session.user.id.uuidString, jwt: session.accessToken)
        currentSession = sessionData
        notifySessionChange(sessionData)
        return sessionData.jwt
#else
        guard let session = currentSession else {
            throw FortuneError.unauthorized
        }
        return session.jwt
#endif
    }

    private func notifySessionChange(_ session: SessionData?) {
        sessionContinuations.forEach { $0.yield(session) }
    }
}

struct SessionData {
    let userId: String
    let jwt: String
}
