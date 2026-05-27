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

    // MARK: - Offering

    func fetchPaywallPlans() async throws -> [PaywallPlan] {
#if canImport(RevenueCat)
        let offerings = try await Purchases.shared.offerings()
        guard let offering = offerings.current else { return PaywallPlan.fallbackPlans }

        var plans: [PaywallPlan] = []
        if let monthly = offering.monthly {
            plans.append(makePlan(kind: .monthly, package: monthly, savingsBadge: nil))
        }
        if let annual = offering.annual {
            plans.append(makePlan(
                kind: .annual,
                package: annual,
                savingsBadge: savingsBadge(monthly: offering.monthly, annual: annual)
            ))
        }

        return plans.isEmpty ? PaywallPlan.fallbackPlans : plans
#else
        return PaywallPlan.fallbackPlans
#endif
    }

    // MARK: - 購入

    func purchase(plan: PaywallPlan) async throws -> SubscriptionTier {
#if canImport(RevenueCat)
        let offerings = try await Purchases.shared.offerings()
        let package = plan.kind == .annual ? offerings.current?.annual : offerings.current?.monthly
        guard let package else { throw RevenueCatError.packageNotFound }
        let result = try await Purchases.shared.purchase(package: package)
        return mapEntitlement(result.customerInfo)
#else
        return .premium
#endif
    }

    func logOut() async {
#if canImport(RevenueCat)
        _ = try? await Purchases.shared.logOut()
#endif
    }

    func restorePurchases() async throws -> SubscriptionTier {
#if canImport(RevenueCat)
        let info = try await Purchases.shared.restorePurchases()
        return mapEntitlement(info)
#else
        return .premium
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

#if canImport(RevenueCat)
    private func makePlan(kind: PaywallPlanKind, package: Package, savingsBadge: String?) -> PaywallPlan {
        PaywallPlan(
            kind: kind,
            title: NSLocalizedString(kind.labelKey, comment: ""),
            priceText: "\(package.localizedPriceString)\(kind.periodSuffix)",
            savingsBadge: savingsBadge ?? kind.fallbackSavingsBadge,
            isAvailable: true
        )
    }

    private func savingsBadge(monthly: Package?, annual: Package) -> String? {
        guard let monthly else { return PaywallPlanKind.annual.fallbackSavingsBadge }
        let savings = monthly.storeProduct.price * Decimal(12) - annual.storeProduct.price
        guard savings > 0 else { return nil }

        let formatter = annual.storeProduct.priceFormatter ?? NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = annual.storeProduct.currencyCode

        let number = NSDecimalNumber(decimal: savings)
        let formatted = formatter.string(from: number) ?? "\(number)"
        return String(format: NSLocalizedString("plan.savings.format", comment: ""), formatted)
    }
#endif
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
