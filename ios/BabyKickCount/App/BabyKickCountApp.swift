import SwiftUI
import SwiftData

@main
struct BabyKickCountApp: App {
    // The container is built explicitly (rather than with the
    // `.modelContainer(for:)` convenience, which is otherwise identical) so
    // the sync service can ingest records the watch delivers while no view
    // hierarchy exists yet — a background transferUserInfo wake.
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
        PhoneSyncService.shared.configure(container: container, preferences: preferences)
        PhoneSyncService.shared.activate()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(preferences)
        }
        .modelContainer(container)
    }
}
