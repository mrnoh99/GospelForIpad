import SwiftUI
import AppIntents

@main
struct GospelForIpadApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    
    init() {
        // App Shortcuts 강제 업데이트
        Task { @MainActor in
            GospelForIpadShortcuts.updateAppShortcutParameters()
        }
        #if DEBUG
        // The Lectionary is first-class data — sweep all three Sunday cycles at launch.
        Task { @MainActor in
            LectionaryValidator.validate()
        }
        #endif
    }
}
