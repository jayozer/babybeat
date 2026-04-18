import SwiftUI
import SwiftData

@main
struct BabyKickCountApp: App {
    @StateObject private var preferences = PreferencesStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(preferences)
        }
        .modelContainer(for: [KickSession.self, KickEvent.self])
    }
}
