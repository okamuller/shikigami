import Foundation
import Observation

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
            await RevenueCatManager.shared.logOut()
            try? await authClient.signOut()
            onDeleted()
        } catch {
            self.error = error
        }
    }
}
