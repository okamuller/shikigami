import SwiftUI
import SwiftData

@main
struct ShikigamiApp: App {
    private let container: ModelContainer
    private let deps: AppDependencies

    init() {
        let c = try! ModelContainer(for: UserProfile.self, FortuneRecord.self, SubscriptionSnapshot.self)
        container = c
        deps = AppDependencies.live(modelContainer: c)
    }

    var body: some Scene {
        WindowGroup {
            RootView(deps: deps)
        }
        .modelContainer(container)
    }
}
