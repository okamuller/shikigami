import Foundation

protocol FortuneRepository: Sendable {
    func fetchHistory(limit: Int) async throws -> [Fortune]
}

// MARK: - Supabase 実装

final class SupabaseFortuneRepository: FortuneRepository, Sendable {
    private let baseURL: URL
    private let session: URLSession
    private let jwtProvider: @Sendable () async throws -> String

    init(baseURL: URL, session: URLSession = .shared, jwtProvider: @escaping @Sendable () async throws -> String) {
        self.baseURL = baseURL
        self.session = session
        self.jwtProvider = jwtProvider
    }

    func fetchHistory(limit: Int = 10) async throws -> [Fortune] {
        let jwt = try await jwtProvider()
        let url = baseURL.appendingPathComponent("rest/v1/fortunes")
            .appending(queryItems: [
                URLQueryItem(name: "select", value: "id,response,topic,created_at"),
                URLQueryItem(name: "order", value: "created_at.desc"),
                URLQueryItem(name: "limit", value: "\(limit)"),
            ])

        var req = URLRequest(url: url)
        req.setValue("Bearer \(jwt)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, _) = try await session.data(for: req)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([Fortune].self, from: data)
    }
}

// MARK: - スタブ（テスト用）

final class StubFortuneRepository: FortuneRepository, Sendable {
    var history: [Fortune] = []
    func fetchHistory(limit: Int) async throws -> [Fortune] { Array(history.prefix(limit)) }
}
