import SwiftUI
import SwiftData

/// Root of the watch experience, using the Workout app's grammar: the tap
/// surface is the whole default page, lifecycle controls live one swipe away
/// so a 40mm screen cannot mis-tap End mid-count, and a finished session
/// swaps to the summary.
struct WatchSessionView: View {
    private enum Page: Int {
        case controls = 0
        case tap = 1
    }

    @EnvironmentObject private var preferences: PreferencesStore
    @ObservedObject private var sync = WatchSyncService.shared
    @StateObject private var viewModel: SessionViewModel
    @State private var selectedPage = Page.tap.rawValue

    init(context: ModelContext, preferences: PreferencesStore) {
        // Everything stays inside the autoclosure so re-renders of the parent
        // never construct a throwaway view model (which would fetch the
        // active session and briefly start a ticking task).
        _viewModel = StateObject(wrappedValue: SessionViewModel(
            store: SessionStore(context: context),
            preferences: preferences,
            feedback: WatchFeedbackService.shared,
            onMutation: { WatchSyncService.shared.handle(mutation: $0) }
        ))
    }

    var body: some View {
        Group {
            if viewModel.isFinished {
                WatchSummaryView(viewModel: viewModel)
            } else {
                TabView(selection: $selectedPage) {
                    WatchControlsView(viewModel: viewModel)
                        .tag(Page.controls.rawValue)

                    WatchTapSurface(
                        viewModel: viewModel,
                        blockedByPhone: sync.counterpartHasActiveSession && viewModel.session == nil
                    )
                    .tag(Page.tap.rawValue)
                }
                .tabViewStyle(.page)
            }
        }
    }
}
