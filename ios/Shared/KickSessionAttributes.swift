import ActivityKit
import Foundation

/// The Live Activity's shape, compiled into both the app and the widget
/// extension.
///
/// `ContentState` is passed **by value** from the app to the extension, so the
/// extension never reads SwiftData — which is why the Live Activity works with
/// no App Group and no store migration.
struct KickSessionAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var kickCount: Int
        var targetCount: Int
        /// Absolute, so the Lock Screen can count itself down without anything
        /// of ours being alive. Never send per-second updates.
        var windowEnd: Date
        var isPaused: Bool

        var progress: Double {
            guard targetCount > 0 else { return 0 }
            return min(1, Double(kickCount) / Double(targetCount))
        }
    }

    let sessionID: UUID
}
