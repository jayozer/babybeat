import Foundation

/// The single handle App Intents use to reach the running session.
///
/// Holds a strong reference for the process lifetime on purpose. Siri can
/// launch the app into the background with no scene on screen, in which case
/// nothing else retains the view model — a weak reference would be nil exactly
/// when an intent needs it most.
///
/// Registration is first-write-wins: SwiftUI may re-create the `App` value,
/// but `@StateObject` keeps the object made on the first pass, so later
/// registrations would point at a view model nothing is displaying.
@MainActor
enum IntentBridge {
    private(set) static var session: SessionViewModel?

    static func register(_ viewModel: SessionViewModel) {
        guard session == nil else { return }
        session = viewModel

        // Shared intents (the Live Activity's "+1") reach the app through a
        // closure rather than a direct reference, so the widget extension can
        // compile the same declaration without dragging in the session layer.
        LiveActivityIntentHandlers.logTap = { [weak viewModel] in
            guard let viewModel else { throw LiveActivityIntentError.unavailable }
            viewModel.tap()
        }
    }
}
