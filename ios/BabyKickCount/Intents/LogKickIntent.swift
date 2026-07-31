import AppIntents

/// The marquee intent. Logging a movement without unlocking and opening the
/// app is a genuinely better interaction than the tap pad when your hands are
/// busy, which in the third trimester is most of the time.
///
/// Runs in the app's own process — the system launches it in the background if
/// needed — so it shares the one `ModelContext` and needs no app group.
struct LogKickIntent: AppIntent {
    static let title: LocalizedStringResource = "Log a tap"
    static let description = IntentDescription(
        "Records a movement. Starts a new session if one isn't already running.",
        categoryName: "Counting"
    )

    /// Deliberately stays in the background: the whole point is not having to
    /// look at the screen.
    static let openAppWhenRun = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let count = try await MainActor.run { () throws -> Int in
            guard let viewModel = IntentBridge.session else {
                throw LittletapsIntentError.unavailable
            }
            // Matches the tap pad: the first tap creates and starts a session.
            viewModel.tap()
            return viewModel.kickCount
        }

        return .result(dialog: "That's \(count). Nice.")
    }
}
