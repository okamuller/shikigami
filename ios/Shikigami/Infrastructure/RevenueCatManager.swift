import Foundation
#if canImport(RevenueCat)
import RevenueCat
#endif

final class RevenueCatManager: Sendable {
    static let shared = RevenueCatManager()

    private init() {}

    // MARK: - SDK 初期化

    /// Apple Sign In 完了後に呼び出す
    /// appUserId = Supabase auth.users.id（UUID文字列）でないと
    /// revenuecat-webhook の app_user_id と一致しない
    func configure(apiKey: String, userId: String) {
#if canImport(RevenueCat)
        Purchases.configure(withAPIKey: apiKey, appUserID: userId)
#endif
    }

    // MARK: - Tier 取得

    func fetchTier() async -> SubscriptionTier {
#if canImport(RevenueCat)
        guard let info = try? await Purchases.shared.customerInfo() else { return .free }
        return mapEntitlement(info)
#else
        return .free
#endif
    }

    // MARK: - 購入

    func purchase(plan: PaywallPlan) async throws {
#if canImport(RevenueCat)
        let offerings = try await Purchases.shared.offerings()
        let package = plan == .annual ? offerings.current?.annual : offerings.current?.monthly
        guard let package else { throw RevenueCatError.packageNotFound }
        _ = try await Purchases.shared.purchase(package: package)
#endif
    }

    func restorePurchases() async throws {
#if canImport(RevenueCat)
        _ = try await Purchases.shared.restorePurchases()
#endif
    }

    // MARK: - プライベートヘルパー

    // RevenueCat CustomerInfo のエンタイトルメントを SubscriptionTier にマップ
    // divine_ プレフィックスのエンタイトルメントは divine tier
    private func mapEntitlement(_ info: Any?) -> SubscriptionTier {
#if canImport(RevenueCat)
        guard let info = info as? CustomerInfo else { return .free }
        if info.entitlements.active.keys.contains(where: { $0.hasPrefix("divine") }) {
            return .divine
        }
        if info.entitlements.active.keys.contains("premium") {
            return .premium
        }
#endif
        return .free
    }
}

enum RevenueCatError: LocalizedError {
    case packageNotFound

    var errorDescription: String? {
        switch self {
        case .packageNotFound:
            return "購入プランが見つかりません。"
        }
    }
}
