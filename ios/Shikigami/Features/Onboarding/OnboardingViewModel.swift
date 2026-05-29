import Foundation
import Observation

enum OnboardingStep: CaseIterable {
    case welcome
    case birthDate
    case gender
    case topic
    case shikigamiReveal
}

@Observable
final class OnboardingViewModel {
    var currentStep: OnboardingStep = .welcome
    var birthDate: Date = Calendar.current.date(byAdding: .year, value: -30, to: .now) ?? .now
    var gender: Gender = .none
    var topic: Topic?
    var meishiki: Meishiki?
    var isLoading = false
    var error: String?

    private let userRepo: UserRepository
    // authClient は SettingsView のアカウント削除で利用（ここでは保持のみ）
    let authClient: SupabaseAuthClient

    init(userRepo: UserRepository, authClient: SupabaseAuthClient) {
        self.userRepo = userRepo
        self.authClient = authClient
    }

    func advance() {
        let steps = OnboardingStep.allCases
        guard let idx = steps.firstIndex(of: currentStep), idx + 1 < steps.count else { return }
        currentStep = steps[idx + 1]
    }

    func calculateMeishiki() {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month, .day], from: birthDate)
        guard let y = comps.year, let m = comps.month, let d = comps.day else { return }
        meishiki = SeimeiEngine.calc(year: y, month: m, day: d)
    }

    func completeOnboarding() async -> AppUser? {
        isLoading = true
        defer { isLoading = false }

        calculateMeishiki()
        guard let m = meishiki else { return nil }

        // local-first: 端末固有の安定 UUID を使用。Supabase セッションは不要。
        let userId = stableLocalUserId()
        let user = AppUser(
            id: userId,
            birthDate: birthDate,
            gender: gender,
            shikigamiId: m.shikigamiIndex
        )

        saveMeishiki(m, for: user.id)

        do {
            try await userRepo.upsertUser(user)
            return user
        } catch {
            self.error = error.localizedDescription
            return nil
        }
    }

    // MARK: - Private helpers

    // UserDefaults に永続化した端末固有 UUID を返す（初回は新規生成）
    private func stableLocalUserId() -> UUID {
        let key = "local_user_id"
        if let str = UserDefaults.standard.string(forKey: key),
           let id = UUID(uuidString: str) {
            return id
        }
        let id = UUID()
        UserDefaults.standard.set(id.uuidString, forKey: key)
        return id
    }

    private func saveMeishiki(_ m: Meishiki, for userId: UUID) {
        let payload = MeishikiPayload(
            kanIndex: m.kanIndex,
            shiIndex: m.shiIndex,
            shikigamiIndex: m.shikigamiIndex,
            gogyo: m.gogyo.rawValue,
            score: m.score
        )
        if let data = try? JSONEncoder().encode(payload) {
            UserDefaults.standard.set(data, forKey: "meishiki_\(userId.uuidString)")
        }
    }
}
