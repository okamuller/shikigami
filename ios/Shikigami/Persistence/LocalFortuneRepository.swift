import Foundation
import SwiftData

// local-first 版 FortuneRepository。SwiftData の FortuneRecord を読み込む。
// docs/local-first-migration.md 参照。
final class LocalFortuneRepository: FortuneRepository, @unchecked Sendable {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchHistory(limit: Int) async throws -> [Fortune] {
        var descriptor = FetchDescriptor<FortuneRecord>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return try context.fetch(descriptor).map { r in
            Fortune(
                id: r.id,
                text: r.response,
                cached: false,
                isFallback: false,
                tokensIn: 0,
                tokensOut: 0,
                createdAt: r.createdAt,
                topic: Topic(rawValue: r.topic) ?? .destiny
            )
        }
    }
}
