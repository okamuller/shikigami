import Foundation
import AuthenticationServices

// Supabase Auth ラッパー
// supabase-swift SDK（github.com/supabase/supabase-swift ~> 2.0）を使用
// 実際の Supabase クライアントは SupabaseClient 型を想定
// NOTE: Xcode プロジェクトに supabase-swift を追加後、import Supabase のコメントを外すこと

// import Supabase  ← Xcode 側で有効化

final class SupabaseAuthClient {
    // MARK: - State

    private(set) var currentSession: SessionData?
    private var sessionContinuations: [AsyncStream<SessionData?>.Continuation] = []

    // MARK: - Apple Sign In

    /// Apple Sign In JWT + nonce を使って Supabase Auth にサインイン
    /// Xcode プロジェクトでは supabase.auth.signInWithIdToken を呼び出す
    func signInWithApple(idToken: String, nonce: String) async throws {
        // TODO: supabase.auth.signInWithIdToken(credentials: .init(provider: .apple, idToken: idToken, nonce: nonce))
        // 仮実装：セッション確立後に currentSession を更新
        let mockSession = SessionData(userId: UUID().uuidString, jwt: idToken)
        currentSession = mockSession
        notifySessionChange(mockSession)
    }

    func signOut() async throws {
        // TODO: try await supabase.auth.signOut()
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
        guard let session = currentSession else {
            throw FortuneError.unauthorized
        }
        return session.jwt
    }

    private func notifySessionChange(_ session: SessionData?) {
        sessionContinuations.forEach { $0.yield(session) }
    }
}

struct SessionData {
    let userId: String
    let jwt: String
}
