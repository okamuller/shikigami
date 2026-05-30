import SwiftUI
import SwiftData

struct FortuneInputView: View {
    let deps: AppDependencies
    let user: AppUser
    let engine: FortuneEngine

    @State private var vm: FortuneViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    init(deps: AppDependencies, user: AppUser, engine: FortuneEngine) {
        self.deps = deps
        self.user = user
        self.engine = engine
        // saveRecord は onAppear で modelContext が確定してから差し替える
        _vm = State(initialValue: FortuneViewModel(
            engine: engine,
            topic: .destiny,
            userId: user.id,
            claudeClient: deps.claudeClient,
            userRepo: deps.userRepo
        ))
    }

    var body: some View {
        ZStack {
            StarfieldView()

            VStack(spacing: 0) {
                // ナビゲーションバー
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundStyle(Color.white.opacity(0.6))
                    }
                    Spacer()
                    Text(String(format: NSLocalizedString("fortune.input.title.format", comment: ""), NSLocalizedString(engine.nameKey, comment: "")))
                        .shikigamiFont(.label)
                        .foregroundStyle(Color.white)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)

                ScrollView {
                    VStack(spacing: 28) {
                        // トピック選択
                        VStack(alignment: .leading, spacing: 12) {
                            Text(NSLocalizedString("fortune.input.topicLabel", comment: ""))
                                .shikigamiFont(.label)
                                .foregroundStyle(Color.white.opacity(0.6))

                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(Topic.allCases) { t in
                                    TopicChip(topic: t, isSelected: vm.selectedTopic == t) {
                                        vm.selectedTopic = t
                                    }
                                }
                            }
                        }

                        // 質問入力
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(NSLocalizedString("fortune.input.questionLabel", comment: ""))
                                    .shikigamiFont(.label)
                                    .foregroundStyle(Color.white.opacity(0.6))
                                Spacer()
                                Text("\(vm.question.count)/80")
                                    .shikigamiFont(.label)
                                    .foregroundStyle(vm.question.count > 80 ? Color.crimsonRed : Color.white.opacity(0.4))
                            }

                            TextEditor(text: $vm.question)
                                .shikigamiFont(.body)
                                .foregroundStyle(Color.white)
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 100, maxHeight: 160)
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.oracleGold.opacity(0.3), lineWidth: 1)
                                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.04)))
                                )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }

                // CTA ボタン
                VStack {
                    if vm.isGenerating {
                        PentagramView(size: 48, isSpinning: true)
                            .padding(.vertical, 8)
                    } else {
                        CTAButton(
                            title: NSLocalizedString(engine.ctaKey, comment: ""),
                            isEnabled: vm.canGenerate
                        ) {
                            Task { await vm.generate() }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 32)
            }
        }
        // modelContext が確定した時点でクロージャを差し込む
        .task {
            vm.saveRecord = { [modelContext] record in
                modelContext.insert(record)
            }
            vm.fetchRecord = { [modelContext] hash in
                let todayStart = Calendar.current.startOfDay(for: Date())
                var descriptor = FetchDescriptor<FortuneRecord>(
                    predicate: #Predicate { $0.inputHash == hash && $0.createdAt >= todayStart }
                )
                descriptor.fetchLimit = 1
                return try? modelContext.fetch(descriptor).first
            }
            // FR-EN-04: 当日より前の直近 5 件を取得。先に絞り込んでから日付フィルタすると
            // 今日の鑑定が 5 件以上ある場合に結果が空になるため predicate で対応。
            vm.fetchRecentRecords = { [modelContext] in
                let todayStart = Calendar.current.startOfDay(for: Date())
                var descriptor = FetchDescriptor<FortuneRecord>(
                    predicate: #Predicate { $0.createdAt < todayStart },
                    sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
                )
                descriptor.fetchLimit = 5
                return (try? modelContext.fetch(descriptor)) ?? []
            }
        }
        .sheet(isPresented: Binding(
            get: { vm.fortune != nil },
            set: { if !$0 { vm.fortune = nil } }
        )) {
            if let fortune = vm.fortune {
                FortuneResultView(
                    fortune: fortune,
                    engine: engine,
                    deps: deps,
                    tier: .free
                )
            }
        }
        .sheet(isPresented: $vm.showPaywall) {
            PaywallView(partialText: "")
        }
    }
}

private struct TopicChip: View {
    let topic: Topic
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(topic.icon).font(.system(size: 14))
                Text(topic.labelJa).shikigamiFont(.label)
            }
            .foregroundStyle(isSelected ? Color.voidBlack : Color.white)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? topic.accentColor : Color.white.opacity(0.07))
            )
        }
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}
