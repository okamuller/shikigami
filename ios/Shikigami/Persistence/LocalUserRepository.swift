import Foundation
import SwiftData

// local-first 版 UserRepository。Supabase を使わず SwiftData の UserProfile を読み書きする。
// docs/local-first-migration.md 参照。
// ModelContext は呼び出しごとに生成し、共有による並行アクセス問題を回避する。
final class LocalUserRepository: UserRepository, Sendable {
    private let container: ModelContainer

    init(container: ModelContainer) {
        self.container = container
    }

    func fetchUser() async throws -> AppUser {
        let context = ModelContext(container)
        let profiles = try context.fetch(FetchDescriptor<UserProfile>())
        guard let p = profiles.first else { throw URLError(.zeroByteResource) }
        return AppUser(
            id: p.localUserId,
            birthDate: p.birthDate,
            gender: Gender(rawValue: p.gender) ?? .none,
            shikigamiId: p.shikigamiId
        )
    }

    func upsertUser(_ user: AppUser) async throws {
        let context = ModelContext(container)
        let profiles = try context.fetch(FetchDescriptor<UserProfile>())
        if let existing = profiles.first {
            if let bd = user.birthDate { existing.birthDate = bd }
            existing.gender = user.gender.rawValue
            if let sid = user.shikigamiId { existing.shikigamiId = sid }
        } else {
            context.insert(UserProfile(
                localUserId: user.id,
                birthDate: user.birthDate ?? .now,
                gender: user.gender.rawValue,
                shikigamiId: user.shikigamiId ?? 0
            ))
        }
        try context.save()
    }

    func deleteAccount() async throws {
        // local-first キーを UserDefaults から削除してから SwiftData を消す
        if let idStr = UserDefaults.standard.string(forKey: "local_user_id") {
            UserDefaults.standard.removeObject(forKey: "meishiki_\(idStr)")
        }
        UserDefaults.standard.removeObject(forKey: "local_user_id")

        let context = ModelContext(container)
        try context.delete(model: UserProfile.self)
        try context.delete(model: FortuneRecord.self)
        try context.delete(model: SubscriptionSnapshot.self)
        try context.save()
    }
}
