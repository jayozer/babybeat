import SwiftUI
import SwiftData

@main
struct BabyKickCountApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    @StateObject private var preferences: PreferencesStore
    @StateObject private var notifications = NotificationService.shared
    @StateObject private var sessionViewModel: SessionViewModel

    private let container: ModelContainer

    /// The container and the session view model are built here rather than
    /// inside `SessionView` so that App Intents have something to talk to.
    /// An intent invoked by Siri runs in this process with no scene on screen,
    /// and a view-owned `@StateObject` would be unreachable from it — worse, a
    /// second `SessionStore` on a second `ModelContext` could write a kick the
    /// live view model never sees.
    init() {
        let container: ModelContainer
        do {
            container = try ModelContainer(for: KickSession.self, KickEvent.self)
        } catch {
            // Same outcome as the implicit `.modelContainer(for:)` this
            // replaced: without a store there is no app.
            fatalError("Could not open the Littletaps data store: \(error)")
        }
        self.container = container

        let preferences = PreferencesStore()
        let viewModel = SessionViewModel(
            store: SessionStore(context: container.mainContext),
            preferences: preferences
        )
        _preferences = StateObject(wrappedValue: preferences)
        _sessionViewModel = StateObject(wrappedValue: viewModel)
        IntentBridge.register(viewModel)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(preferences)
                .environmentObject(notifications)
                .environmentObject(sessionViewModel)
        }
        .modelContainer(container)
    }
}
