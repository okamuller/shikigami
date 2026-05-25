import Foundation
import Observation

enum PaywallPlanKind: String, CaseIterable {
    case monthly
    case annual

    var labelKey: String {
        switch self {
        case .monthly: return "plan.monthly.label"
        case .annual: return "plan.annual.label"
        }
    }

    var fallbackPriceText: String {
        switch self {
        case .monthly: return "¥450 / 月"
        case .annual: return "¥3,800 / 年"
        }
    }

    var periodSuffix: String {
        switch self {
        case .monthly: return " / 月"
        case .annual: return " / 年"
        }
    }

    var fallbackSavingsBadge: String? {
        switch self {
        case .monthly: return nil
        case .annual: return "¥1,600 お得"
        }
    }
}

struct PaywallPlan: Identifiable, Hashable {
    let kind: PaywallPlanKind
    let title: String
    let priceText: String
    let savingsBadge: String?
    let isAvailable: Bool

    var id: String { kind.rawValue }

    static var fallbackPlans: [PaywallPlan] {
        PaywallPlanKind.allCases.map { kind in
            PaywallPlan(
                kind: kind,
                title: NSLocalizedString(kind.labelKey, comment: ""),
                priceText: kind.fallbackPriceText,
                savingsBadge: kind.fallbackSavingsBadge,
                isAvailable: true
            )
        }
    }
}

@Observable
final class PaywallViewModel {
    var plans: [PaywallPlan] = PaywallPlan.fallbackPlans
    var selectedPlanID: PaywallPlan.ID = PaywallPlanKind.monthly.rawValue
    var isLoadingPlans = false
    var isPurchasing = false
    var purchaseError: String?
    var isCompleted = false

    private let revenueCat: RevenueCatManager

    init(revenueCat: RevenueCatManager = .shared) {
        self.revenueCat = revenueCat
    }

    var selectedPlan: PaywallPlan? {
        plans.first { $0.id == selectedPlanID } ?? plans.first
    }

    func loadPlans() async {
        isLoadingPlans = true
        purchaseError = nil
        defer { isLoadingPlans = false }

        do {
            let fetchedPlans = try await revenueCat.fetchPaywallPlans()
            plans = fetchedPlans.isEmpty ? PaywallPlan.fallbackPlans : fetchedPlans
            if !plans.contains(where: { $0.id == selectedPlanID }) {
                selectedPlanID = plans.first?.id ?? PaywallPlanKind.monthly.rawValue
            }
        } catch {
            plans = PaywallPlan.fallbackPlans
            purchaseError = error.localizedDescription
        }
    }

    func purchase() async {
        guard let selectedPlan else { return }
        isPurchasing = true
        purchaseError = nil
        defer { isPurchasing = false }

        do {
            let tier = try await revenueCat.purchase(plan: selectedPlan)
            isCompleted = tier != .free
            if !isCompleted {
                purchaseError = NSLocalizedString("plan.error.noEntitlement", comment: "")
            }
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    func restore() async {
        isPurchasing = true
        purchaseError = nil
        defer { isPurchasing = false }

        do {
            let tier = try await revenueCat.restorePurchases()
            isCompleted = tier != .free
            if !isCompleted {
                purchaseError = NSLocalizedString("plan.error.restoreNotFound", comment: "")
            }
        } catch {
            purchaseError = error.localizedDescription
        }
    }
}
