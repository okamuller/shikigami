import Foundation
import SwiftData

// local-first 版 FortuneRepository。SwiftData の FortuneRecord を読み込む。
// docs/local-first-migration.md 参照。
// ModelContext は呼び出しごとに生成し、共有による並行アクセス問題を回避する。
final class LocalFortuneRepository: FortuneRepository, Sendable {
    private let container: ModelContainer

    init(container: ModelContainer) {
        self.container = container
    }

    func fetchHistory(limit: Int) async throws -> [Fortune] {
        let context = ModelContext(container)
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
