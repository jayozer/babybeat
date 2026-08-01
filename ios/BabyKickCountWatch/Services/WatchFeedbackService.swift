import WatchKit

/// Haptics-only feedback for the wrist. The synthesized sounds are not
/// ported: speaker audio during a quiet resting activity is the opposite of
/// what this app is for, and haptics are the native idiom on the watch.
@MainActor
final class WatchFeedbackService: FeedbackProviding {
    static let shared = WatchFeedbackService()

    private init() {}

    func prepare() {}

    func kickFeedback(sound: SoundOption, vibrationEnabled: Bool) {
        guard vibrationEnabled else { return }
        WKInterfaceDevice.current().play(.click)
    }

    func outcomeFeedback(_ status: SessionStatus) {
        switch status {
        case .complete:
            WKInterfaceDevice.current().play(.success)
        case .timeout:
            WKInterfaceDevice.current().play(.notification)
        case .idle, .active, .paused, .endedEarly:
            // Ending early is a deliberate button press; it needs no cue.
            break
        }
    }

    func undoFeedback() {
        WKInterfaceDevice.current().play(.directionDown)
    }
}
