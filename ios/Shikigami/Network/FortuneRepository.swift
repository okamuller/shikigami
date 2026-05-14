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
        // DB の `response` カラムを Fortune.text にマップするため専用 DTO を使用
        let dtos = try decoder.decode([FortuneHistoryDTO].self, from: data)
        return dtos.map(\.fortune)
    }
}

// DB の history クエリ結果 (response カラム) を Fortune に変換する DTO
private struct FortuneHistoryDTO: Decodable {
    let id: UUID
    let response: String
    let topic: Topic
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, response, topic
        case createdAt = "created_at"
    }

    var fortune: Fortune {
        Fortune(
            id: id,
            text: response,
            cached: false,
            isFallback: false,
            tokensIn: 0,
            tokensOut: 0,
            createdAt: createdAt,
            topic: topic
        )
    }
}

// MARK: - スタブ（テスト用）

final class StubFortuneRepository: FortuneRepository, Sendable {
    var history: [Fortune] = []
    func fetchHistory(limit: Int) async throws -> [Fortune] { Array(history.prefix(limit)) }
}
