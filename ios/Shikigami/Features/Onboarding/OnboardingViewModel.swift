import Foundation
import Observation
import ShikigamiEngines

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

    init(userRepo: UserRepository) {
        self.userRepo = userRepo
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

        var user = AppUser(
            id: UUID(),
            birthDate: birthDate,
            gender: gender,
            shikigamiId: m.shikigamiIndex
        )

        // キャッシュ（UserDefaults）に命式を保存
        saveMeishiki(m, for: user.id)

        do {
            try await userRepo.upsertUser(user)
            return user
        } catch {
            self.error = error.localizedDescription
            return nil
        }
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
