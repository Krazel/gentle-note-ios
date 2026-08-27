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
                .onChange(of: scenePhase) { phase in
                    switch phase {
                    case .inactive: model.enteredInactive()
                    case .background: model.enteredBackground()
                    case .active: model.becameActive()
                    @unknown default: break
                    }
                }
        }
    }
}
