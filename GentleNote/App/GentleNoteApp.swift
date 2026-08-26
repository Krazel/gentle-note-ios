import SwiftUI

@main
struct GentleNoteApp: App {
    @StateObject private var model = AppModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(model)
                .preferredColorScheme(nil)
                .onChange(of: scenePhase) { _, phase in
                    switch phase {
                    case .background, .inactive: model.enteredBackground()
                    case .active: model.becameActive()
                    @unknown default: break
                    }
                }
        }
    }
}
