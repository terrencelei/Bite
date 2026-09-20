import SwiftUI

@main
struct BiteApp: App {
    @State private var model = AppModel()
    @State private var nearby = NearbySearchStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
                .environment(nearby)
        }
    }
}
