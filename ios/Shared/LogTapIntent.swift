import AppIntents

/// The "+1" button inside the Live Activity and the Dynamic Island.
///
/// Conforms to `LiveActivityIntent` specifically so it executes in the **app's**
/// process rather than the widget extension's — the extension has no
/// `ModelContext` and could not record a movement.
///
/// The type has to compile into both targets for the widget's `Button(intent:)`
/// to reference it, but the app's session layer must not be dragged into the
/// extension. Hence the handler indirection: the app installs a closure at
/// launch, and the extension compiles the same declaration with nothing
/// registered, which is harmless because the body never runs there.
struct LogTapIntent: AppIntent, LiveActivityIntent {
    static let title: LocalizedStringResource = "Log a tap"
    static let description = IntentDescription("Records a movement from the Lock Screen.")
    static let openAppWhenRun = false

    /// Hidden from Shortcuts and Siri: `LogKickIntent` already covers those
    /// surfaces, and two identically named actions in the Shortcuts list would
    /// be a coin flip for the user. This one exists purely for the button.
    static let isDiscoverable = false

    init() {}

    func perform() async throws -> some IntentResult {
        try await LiveActivityIntentHandlers.performLogTap()
        return .result()
    }
}

/// Bridges shared intents back to the app without the shared code depending on
/// app types.
@MainActor
enum LiveActivityIntentHandlers {
    static var logTap: (() throws -> Void)?

    static func performLogTap() throws {
        guard let logTap else { throw LiveActivityIntentError.unavailable }
        try logTap()
    }
}

enum LiveActivityIntentError: Swift.Error, CustomLocalizedStringResourceConvertible {
    case unavailable

    var localizedStringResource: LocalizedStringResource {
        "Littletaps isn't ready just yet. Open the app and try again."
    }
}
