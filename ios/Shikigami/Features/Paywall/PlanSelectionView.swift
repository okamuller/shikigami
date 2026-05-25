import SwiftUI

struct PlanSelectionView: View {
    @State private var vm = PaywallViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            StarfieldView()

            VStack(spacing: 0) {
                // ヘッダー
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundStyle(Color.white.opacity(0.6))
                    }
                    Spacer()
                    Text(NSLocalizedString("plan.title", comment: ""))
                        .shikigamiFont(.label)
                        .foregroundStyle(Color.white)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 32)

                Spacer()

                if vm.isLoadingPlans {
                    PentagramView(size: 48, isSpinning: true)
                } else {
                    VStack(spacing: 16) {
                        // プランカード
                        ForEach(vm.plans) { plan in
                            PlanCard(
                                plan: plan,
                                isSelected: vm.selectedPlanID == plan.id,
                                onSelect: { vm.selectedPlanID = plan.id }
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                }

                Spacer()

                VStack(spacing: 16) {
                    // 購入ボタン
                    if vm.isPurchasing {
                        PentagramView(size: 44, isSpinning: true)
                    } else {
                        CTAButton(
                            title: NSLocalizedString("plan.cta", comment: ""),
                            isEnabled: vm.selectedPlan != nil
                        ) {
                            Task { await vm.purchase() }
                        }
                        .padding(.horizontal, 24)
                    }

                    if let error = vm.purchaseError {
                        Text(error)
                            .shikigamiFont(.label)
                            .foregroundStyle(Color.crimsonRed)
                            .multilineTextAlignment(.center)
                    }

                    Button(NSLocalizedString("plan.restore", comment: "")) {
                        Task { await vm.restore() }
                    }
                    .shikigamiFont(.label)
                    .foregroundStyle(Color.white.opacity(0.4))

                    // 利用規約・解約案内（Apple 審査対応）
                    Text(NSLocalizedString("plan.legal", comment: ""))
                        .shikigamiFont(.label)
                        .foregroundStyle(Color.white.opacity(0.3))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $vm.isCompleted) {
            PaywallCompletionView()
        }
        .task {
            await vm.loadPlans()
        }
    }
}

private struct PlanCard: View {
    let plan: PaywallPlan
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.title)
                        .shikigamiFont(.heading)
                        .foregroundStyle(Color.white)

                    Text(plan.priceText)
                        .shikigamiFont(.body)
                        .foregroundStyle(Color.oracleGold)
                }

                Spacer()

                if let badge = plan.savingsBadge {
                    Text(badge)
                        .shikigamiFont(.label)
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.crimsonRed)
                        .clipShape(Capsule())
                }

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.oracleGold : Color.white.opacity(0.3))
                    .font(.system(size: 22))
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.oracleGold : Color.white.opacity(0.15), lineWidth: isSelected ? 2 : 1)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isSelected ? Color.oracleGold.opacity(0.08) : Color.white.opacity(0.03))
                    )
            )
        }
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}
