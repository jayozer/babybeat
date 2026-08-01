import AppIntents

struct StartSessionIntent: AppIntent {
    static let title: LocalizedStringResource = "Start counting"
    static let description = IntentDescription(
        "Opens Littletaps and starts a new 2-hour counting session.",
        categoryName: "Counting"
    )

    /// Starting a session implies you want to watch it, so bring the app
    /// forward rather than leaving a silent timer running.
    static let openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        try await MainActor.run {
            guard let viewModel = IntentBridge.session else {
                throw LittletapsIntentError.unavailable
            }
            viewModel.startSession()
        }
        return .result()
    }
}
