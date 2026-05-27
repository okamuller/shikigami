import Foundation
import Observation
import UserNotifications

@Observable
final class SettingsViewModel {
    var isDeleting = false
    var showDeleteConfirmation = false
    var error: Error?

    private let authClient: SupabaseAuthClient
    private let userRepo: UserRepository
    private let onDeleted: () -> Void

    init(authClient: SupabaseAuthClient, userRepo: UserRepository, onDeleted: @escaping () -> Void) {
        self.authClient = authClient
        self.userRepo = userRepo
        self.onDeleted = onDeleted
    }

    func requestDelete() {
        showDeleteConfirmation = true
    }

    func confirmDelete() async {
        isDeleting = true
        defer { isDeleting = false }
        do {
            try await userRepo.deleteAccount()
            // サーバ側削除成功後にローカルデータをクリア
            let center = UNUserNotificationCenter.current()
            let pending = await center.pendingNotificationRequests()
            let dailyIDs = pending.map(\.identifier).filter { $0.hasPrefix("daily_shikigami_word") }
            center.removePendingNotificationRequests(withIdentifiers: dailyIDs)
            // 命式キャッシュを UserDefaults から削除（OnboardingViewModel.saveMeishiki と同じキー）
            if let userId = authClient.currentSession?.userId {
                UserDefaults.standard.removeObject(forKey: "meishiki_\(userId)")
            }
            await RevenueCatManager.shared.logOut()
            try? await authClient.signOut()
            onDeleted()
        } catch {
            self.error = error
        }
    }
}
