import AppIntents

struct EndSessionIntent: AppIntent {
    static let title: LocalizedStringResource = "End the session"
    static let description = IntentDescription(
        "Ends the session that's running and opens the summary.",
        categoryName: "Counting"
    )

    /// Ending is the one destructive-ish action here, so it brings the app
    /// forward: the summary sheet appears immediately and shows exactly what
    /// was saved, which is a clearer confirmation than a spoken prompt.
    static let openAppWhenRun = true

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let count = try await MainActor.run { () throws -> Int in
            guard let viewModel = IntentBridge.session else {
                throw LittletapsIntentError.unavailable
            }
            guard viewModel.isActive || viewModel.isPaused else {
                throw LittletapsIntentError.noActiveSession
            }
            let count = viewModel.kickCount
            viewModel.endEarly()
            return count
        }

        return .result(dialog: "\(NotificationPlanner.tapCount(count)).")
    }
}
