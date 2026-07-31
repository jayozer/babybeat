import SwiftUI
import SwiftData

@main
struct BabyKickCountApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var preferences = PreferencesStore()
    @StateObject private var notifications = NotificationService.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(preferences)
                .environmentObject(notifications)
        }
        .modelContainer(for: [KickSession.self, KickEvent.self])
    }
}
