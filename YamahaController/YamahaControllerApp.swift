import SwiftUI

@main
struct YamahaControllerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // No windows — menu bar only. Settings scene required to satisfy @main.
        Settings { EmptyView() }
    }
}
