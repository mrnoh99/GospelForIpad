import SwiftUI
import AppIntents

@main
struct GospelForIpadApp: App {
    @State private var annotations = AnnotationStore()
    @State private var settings = ReaderSettings()
    @State private var appSettings = AppSettings.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(annotations)
                .environment(settings)
                .environment(appSettings)
                .task {
                    checkAutoBackup()
                }
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

    private func checkAutoBackup() {
        let backupManager = BackupManager.shared
        if backupManager.shouldBackup() {
            _ = backupManager.backup(annotationStore: annotations)
        }
    }
}
