import Foundation
import Observation

enum PaywallPlan: CaseIterable {
    case monthly
    case annual

    var priceJa: String {
        switch self {
        case .monthly: return "¥480 / 月"
        case .annual:  return "¥3,800 / 年"
        }
    }

    var savingsBadge: String? {
        switch self {
        case .monthly: return nil
        case .annual:  return "¥1,960 お得"
        }
    }
}

@Observable
final class PaywallViewModel {
    var selectedPlan: PaywallPlan = .monthly
    var isPurchasing = false
    var purchaseError: String?
    var isCompleted = false

    private let revenueCat: RevenueCatManager

    init(revenueCat: RevenueCatManager = .shared) {
        self.revenueCat = revenueCat
    }

    func purchase() async {
        isPurchasing = true
        purchaseError = nil
        defer { isPurchasing = false }

        do {
            try await revenueCat.purchase(plan: selectedPlan)
            isCompleted = true
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    func restore() async {
        isPurchasing = true
        defer { isPurchasing = false }
        try? await revenueCat.restorePurchases()
    }
}
