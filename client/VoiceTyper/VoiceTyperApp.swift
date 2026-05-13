import SwiftUI

@main
struct VoiceTyperApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            EmptyView()
                .frame(width: 0, height: 0)
                .hidden()
        }
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
        
        Settings {
            SettingsView()
        }
    }
}
