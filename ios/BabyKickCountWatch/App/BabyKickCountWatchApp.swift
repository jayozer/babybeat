import SwiftUI
import SwiftData

@main
struct BabyKickCountWatchApp: App {
    // The watch keeps its own full store: a session must survive the app
    // being suspended mid-count with the phone in another room. The container
    // is built explicitly so the sync service can apply incoming records
    // outside any view hierarchy.
    private let container: ModelContainer
    @StateObject private var preferences: PreferencesStore

    init() {
        do {
            container = try ModelContainer(for: KickSession.self, KickEvent.self)
        } catch {
            fatalError("Could not open the local data store: \(error)")
        }
        let preferences = PreferencesStore()
        _preferences = StateObject(wrappedValue: preferences)
        WatchSyncService.shared.configure(container: container, preferences: preferences)
        WatchSyncService.shared.activate()
    }

    var body: some Scene {
        WindowGroup {
            WatchRootView()
                .environmentObject(preferences)
        }
        .modelContainer(container)
    }
}

/// Gate on the medical disclaimer, mirroring the iPhone's onboarding gate.
/// `hasCompletedOnboarding` is per-device, so the disclaimer is acknowledged
/// once on each wrist regardless of what happened on the phone.
struct WatchRootView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var preferences: PreferencesStore

    var body: some View {
        if preferences.preferences.hasCompletedOnboarding {
            WatchSessionView(context: context, preferences: preferences)
        } else {
            WatchDisclaimerView {
                preferences.update { $0.hasCompletedOnboarding = true }
            }
        }
    }
}
