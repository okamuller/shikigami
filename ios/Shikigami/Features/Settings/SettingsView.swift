import SwiftUI

struct SettingsView: View {
    @State private var vm: SettingsViewModel

    init(deps: AppDependencies, onDeleted: @escaping () -> Void) {
        _vm = State(initialValue: SettingsViewModel(
            authClient: deps.authClient,
            userRepo: deps.userRepo,
            onDeleted: onDeleted
        ))
    }

    var body: some View {
        ZStack {
            StarfieldView()

            VStack(spacing: 0) {
                // ヘッダー
                HStack(spacing: 10) {
                    PentagramView(size: 28)
                    Text(NSLocalizedString("settings.title", comment: ""))
                        .shikigamiFont(.heading)
                        .foregroundStyle(Color.white)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                .padding(.bottom, 32)

                // アカウントセクション
                VStack(alignment: .leading, spacing: 0) {
                    Text(NSLocalizedString("settings.section.account", comment: ""))
                        .shikigamiFont(.label)
                        .foregroundStyle(Color.white.opacity(0.5))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)

                    Button(action: vm.requestDelete) {
                        HStack {
                            Text(NSLocalizedString("settings.deleteAccount", comment: ""))
                                .shikigamiFont(.body)
                                .foregroundStyle(Color.crimsonRed)
                            Spacer()
                            if vm.isDeleting {
                                ProgressView().tint(.crimsonRed)
                            } else {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(Color.crimsonRed.opacity(0.5))
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                    .disabled(vm.isDeleting)
                }
                .background(Color.white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 20)

                Spacer()

                // 免責（特商法・PP への誘導）
                Text(NSLocalizedString("settings.legal", comment: ""))
                    .shikigamiFont(.label)
                    .foregroundStyle(Color.white.opacity(0.3))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 48)
            }
        }
        .confirmationDialog(
            NSLocalizedString("settings.deleteConfirm.title", comment: ""),
            isPresented: $vm.showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(NSLocalizedString("settings.deleteConfirm.cta", comment: ""), role: .destructive) {
                Task { await vm.confirmDelete() }
            }
            Button(NSLocalizedString("settings.deleteConfirm.cancel", comment: ""), role: .cancel) {}
        } message: {
            Text(NSLocalizedString("settings.deleteConfirm.message", comment: ""))
        }
        .alert(
            NSLocalizedString("settings.deleteError.title", comment: ""),
            isPresented: Binding(
                get: { vm.error != nil },
                set: { if !$0 { vm.error = nil } }
            )
        ) {
            Button("OK", role: .cancel) { vm.error = nil }
        } message: {
            Text(vm.error?.localizedDescription ?? "")
        }
    }
}
