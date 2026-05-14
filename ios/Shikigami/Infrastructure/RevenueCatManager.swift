import Foundation

// RevenueCat SDK ラッパー
// Xcode プロジェクトに RevenueCat SDK（github.com/RevenueCat/purchases-ios）を追加後、
// import RevenueCat のコメントを外し、実装を有効化すること

// import RevenueCat  ← Xcode 側で有効化

final class RevenueCatManager: Sendable {
    static let shared = RevenueCatManager()

    private init() {}

    // MARK: - SDK 初期化

    /// Apple Sign In 完了後に呼び出す
    /// appUserId = Supabase auth.users.id（UUID文字列）でないと
    /// revenuecat-webhook の app_user_id と一致しない
    func configure(apiKey: String, userId: String) {
        // TODO: Purchases.configure(withAPIKey: apiKey)
        // TODO: Purchases.shared.logIn(userId) { _, _, _ in }
    }

    // MARK: - Tier 取得

    func fetchTier() async -> SubscriptionTier {
        // TODO: let info = try? await Purchases.shared.customerInfo()
        // return mapEntitlement(info)
        return .free
    }

    // MARK: - 購入

    func purchase(plan: PaywallPlan) async throws {
        // TODO: offerings = try await Purchases.shared.offerings()
        // let package = plan == .annual ? offerings.current?.annual : offerings.current?.monthly
        // try await Purchases.shared.purchase(package: package!)
    }

    func restorePurchases() async throws {
        // TODO: try await Purchases.shared.restorePurchases()
    }

    // MARK: - プライベートヘルパー

    // RevenueCat CustomerInfo のエンタイトルメントを SubscriptionTier にマップ
    // divine_ プレフィックスのエンタイトルメントは divine tier
    private func mapEntitlement(_ info: Any?) -> SubscriptionTier {
        // TODO: implement based on info.entitlements
        return .free
    }
}
