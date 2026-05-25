import Foundation
import AuthenticationServices
import CryptoKit
import Observation
import Security

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
    private var currentNonce: String?

    private let userRepo: UserRepository
    private let authClient: SupabaseAuthClient

    init(userRepo: UserRepository, authClient: SupabaseAuthClient) {
        self.userRepo = userRepo
        self.authClient = authClient
    }

    func advance() {
        let steps = OnboardingStep.allCases
        guard let idx = steps.firstIndex(of: currentStep), idx + 1 < steps.count else { return }
        currentStep = steps[idx + 1]
    }

    func prepareAppleSignIn(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = randomNonce()
        currentNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
    }

    func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let authorization = try result.get()
            guard
                let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                let identityToken = credential.identityToken,
                let idToken = String(data: identityToken, encoding: .utf8),
                let nonce = currentNonce
            else {
                error = NSLocalizedString("error.unauthorized", comment: "")
                return
            }

            try await authClient.signInWithApple(idToken: idToken, nonce: nonce)
            if let apiKey = Bundle.main.infoDictionary?["REVENUECAT_PUBLIC_API_KEY"] as? String,
               !apiKey.isEmpty,
               let userId = authClient.currentSession?.userId {
                RevenueCatManager.shared.configure(apiKey: apiKey, userId: userId)
            }
            advance()
        } catch {
            self.error = error.localizedDescription
        }
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

        // Supabase Auth セッションの userId を使用（RLS: auth.uid() = id が必須）
        guard let sessionUserId = authClient.currentSession?.userId,
              let userId = UUID(uuidString: sessionUserId) else {
            error = NSLocalizedString("error.unauthorized", comment: "")
            return nil
        }

        let user = AppUser(
            id: userId,
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

    private func randomNonce(length: Int = 32) -> String {
        precondition(length > 0)
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            var randoms = [UInt8](repeating: 0, count: 16)
            let status = SecRandomCopyBytes(kSecRandomDefault, randoms.count, &randoms)
            guard status == errSecSuccess else { fatalError("Unable to generate nonce") }

            randoms.forEach { random in
                if remainingLength == 0 { return }
                if Int(random) < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }

        return result
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.map { String(format: "%02x", $0) }.joined()
    }
}
