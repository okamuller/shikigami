import Foundation

// MARK: - Protocol

protocol ClaudeClient: Sendable {
    func generate(request: FortuneRequest) async throws -> FortuneResponse
}

struct FortuneResponse {
    let id: String
    let text: String
    let cached: Bool
    let isFallback: Bool
    let tokensIn: Int
    let tokensOut: Int
}

enum FortuneError: Error, LocalizedError {
    case quotaExceeded
    case rateLimited
    case claudeUnavailable(fallbackText: String)
    case unauthorized
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .quotaExceeded:                return NSLocalizedString("error.quota_exceeded", comment: "")
        case .rateLimited:                  return NSLocalizedString("error.rate_limited", comment: "")
        case .claudeUnavailable:            return NSLocalizedString("error.claude_unavailable", comment: "")
        case .unauthorized:                 return NSLocalizedString("error.unauthorized", comment: "")
        case .networkError(let e):          return e.localizedDescription
        }
    }
}

// MARK: - Supabase 実装

final class SupabaseClaudeClient: ClaudeClient, Sendable {
    private let baseURL: URL
    private let session: URLSession
    // JWT はリクエスト毎に Supabase Auth から取得するため、クロージャで渡す
    private let jwtProvider: @Sendable () async throws -> String

    init(baseURL: URL, session: URLSession = .shared, jwtProvider: @escaping @Sendable () async throws -> String) {
        self.baseURL = baseURL
        self.session = session
        self.jwtProvider = jwtProvider
    }

    func generate(request: FortuneRequest) async throws -> FortuneResponse {
        let jwt = try await jwtProvider()
        let endpoint = baseURL.appendingPathComponent("functions/v1/claude-proxy")

        var urlRequest = URLRequest(url: endpoint, timeoutInterval: 30)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(jwt)", forHTTPHeaderField: "Authorization")

        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)

        return try await performWithRetry(urlRequest: urlRequest)
    }

    // 指数バックオフリトライ（1/2/4/8 秒、最大4回）
    private func performWithRetry(urlRequest: URLRequest) async throws -> FortuneResponse {
        var lastError: Error = FortuneError.networkError(URLError(.unknown))
        let delays: [UInt64] = [1_000_000_000, 2_000_000_000, 4_000_000_000, 8_000_000_000]

        for (attempt, delay) in delays.enumerated() {
            do {
                return try await performRequest(urlRequest)
            } catch FortuneError.quotaExceeded {
                throw FortuneError.quotaExceeded
            } catch FortuneError.unauthorized {
                throw FortuneError.unauthorized
            } catch FortuneError.claudeUnavailable(let text) {
                throw FortuneError.claudeUnavailable(fallbackText: text)
            } catch {
                lastError = error
                if attempt < delays.count - 1 {
                    try await Task.sleep(nanoseconds: delay)
                }
            }
        }
        throw lastError
    }

    private func performRequest(_ urlRequest: URLRequest) async throws -> FortuneResponse {
        let (data, response) = try await session.data(for: urlRequest)
        guard let http = response as? HTTPURLResponse else {
            throw FortuneError.networkError(URLError(.badServerResponse))
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        switch http.statusCode {
        case 200:
            let body = try decoder.decode(FortuneAPIResponse.self, from: data)
            return FortuneResponse(
                id: body.id,
                text: body.text,
                cached: body.cached,
                isFallback: body.isFallback,
                tokensIn: body.tokens.input,
                tokensOut: body.tokens.output
            )
        case 401:
            throw FortuneError.unauthorized
        case 402:
            throw FortuneError.quotaExceeded
        case 429:
            throw FortuneError.rateLimited
        case 503:
            let body = try? decoder.decode(FortuneAPIResponse.self, from: data)
            throw FortuneError.claudeUnavailable(fallbackText: body?.text ?? "")
        default:
            throw FortuneError.networkError(URLError(.badServerResponse))
        }
    }
}

// MARK: - スタブ（テスト用）

final class StubClaudeClient: ClaudeClient, Sendable {
    var result: Result<FortuneResponse, Error>

    init(result: Result<FortuneResponse, Error> = .success(
        FortuneResponse(
            id: "stub-id",
            text: "汝の式神は青龍なり。木の気満ちて、良縁の兆しあらん。\n今は焦らず、天の時を待たれよ。行動は満月の夜まで待つべし。",
            cached: false, isFallback: false, tokensIn: 200, tokensOut: 80
        )
    )) {
        self.result = result
    }

    func generate(request: FortuneRequest) async throws -> FortuneResponse {
        switch result {
        case .success(let r): return r
        case .failure(let e): throw e
        }
    }
}
