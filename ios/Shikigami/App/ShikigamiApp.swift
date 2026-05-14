import SwiftUI

@main
struct ShikigamiApp: App {
    private let deps = AppDependencies.live()

    var body: some Scene {
        WindowGroup {
            RootView(deps: deps)
        }
    }
}
