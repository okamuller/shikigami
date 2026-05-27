import SwiftUI
import SwiftData

@main
struct ShikigamiApp: App {
    private let deps = AppDependencies.live()

    var body: some Scene {
        WindowGroup {
            RootView(deps: deps)
        }
        .modelContainer(for: [UserProfile.self, FortuneRecord.self, SubscriptionSnapshot.self])
    }
}
