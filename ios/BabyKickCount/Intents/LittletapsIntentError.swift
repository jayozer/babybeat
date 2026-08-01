import AppIntents
import Foundation

/// Errors an intent can surface to Siri or the Shortcuts app.
///
/// Conforming to `CustomLocalizedStringResourceConvertible` is what makes Siri
/// speak these sentences instead of a generic "something went wrong".
enum LittletapsIntentError: Swift.Error, CustomLocalizedStringResourceConvertible {
    case unavailable
    case noActiveSession

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .unavailable:
            return "Littletaps isn't ready just yet. Open the app and try again."
        case .noActiveSession:
            return "There's no session running right now."
        }
    }
}
