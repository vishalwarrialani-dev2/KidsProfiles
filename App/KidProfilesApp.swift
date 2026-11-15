import SwiftUI

@main
struct KidProfilesApp: App {
    @StateObject private var model = AppModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(model)
        }
        .onChange(of: scenePhase) { _, phase in
            // Lock the parent area whenever the app leaves the screen.
            if phase != .active { model.unlocked = false }
            if phase == .active { model.refresh() }
        }
    }
}
