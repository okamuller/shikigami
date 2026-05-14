import Foundation
import Observation

@Observable
final class HomeViewModel {
    var todayFortune: Fortune?
    var recentHistory: [Fortune] = []
    var isLoading = false
    var tier: SubscriptionTier = .free

    private let fortuneRepo: FortuneRepository
    private let revenueCat: RevenueCatManager

    init(fortuneRepo: FortuneRepository, revenueCat: RevenueCatManager = .shared) {
        self.fortuneRepo = fortuneRepo
        self.revenueCat = revenueCat
    }

    func onAppear() async {
        isLoading = true
        defer { isLoading = false }

        async let historyTask = fortuneRepo.fetchHistory(limit: 3)
        async let tierTask = revenueCat.fetchTier()

        recentHistory = (try? await historyTask) ?? []
        tier = await tierTask

        // 当日の最新鑑定を today fortune として表示
        let todayStart = Calendar.current.startOfDay(for: .now)
        todayFortune = recentHistory.first { $0.createdAt >= todayStart }
    }
}
