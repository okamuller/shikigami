import Foundation

protocol UserRepository: Sendable {
    func fetchUser() async throws -> AppUser
    func upsertUser(_ user: AppUser) async throws
}

// MARK: - Supabase 実装

final class SupabaseUserRepository: UserRepository, Sendable {
    private let baseURL: URL
    private let session: URLSession
    private let jwtProvider: @Sendable () async throws -> String

    init(baseURL: URL, session: URLSession = .shared, jwtProvider: @escaping @Sendable () async throws -> String) {
        self.baseURL = baseURL
        self.session = session
        self.jwtProvider = jwtProvider
    }

    func fetchUser() async throws -> AppUser {
        let jwt = try await jwtProvider()
        let url = baseURL.appendingPathComponent("rest/v1/users")
            .appending(queryItems: [URLQueryItem(name: "select", value: "*"), URLQueryItem(name: "limit", value: "1")])

        var req = URLRequest(url: url)
        req.setValue("Bearer \(jwt)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, _) = try await session.data(for: req)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        let users = try decoder.decode([AppUser].self, from: data)
        guard let user = users.first else { throw URLError(.zeroByteResource) }
        return user
    }

    func upsertUser(_ user: AppUser) async throws {
        let jwt = try await jwtProvider()
        let url = baseURL.appendingPathComponent("rest/v1/users")

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(jwt)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("resolution=merge-duplicates", forHTTPHeaderField: "Prefer")

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        req.httpBody = try encoder.encode(user)

        _ = try await session.data(for: req)
    }
}

// MARK: - スタブ（テスト用）

final class StubUserRepository: UserRepository, Sendable {
    var user: AppUser

    init(user: AppUser = AppUser(id: UUID(), birthDate: nil, gender: .none, shikigamiId: nil)) {
        self.user = user
    }

    func fetchUser() async throws -> AppUser { user }
    func upsertUser(_ updated: AppUser) async throws { user = updated }
}
