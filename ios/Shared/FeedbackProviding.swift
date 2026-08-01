import Foundation

/// Platform seam for session feedback. The iPhone plays synthesized sounds
/// plus impact haptics; the watch plays `WKInterfaceDevice` haptics only, so
/// the shared `SessionViewModel` talks to this protocol instead of a concrete
/// service.
@MainActor
protocol FeedbackProviding: AnyObject {
    /// Warm up whatever the platform needs (audio engine, haptic engine).
    func prepare()

    /// Feedback for a logged kick.
    func kickFeedback(sound: SoundOption, vibrationEnabled: Bool)

    /// Feedback when a session reaches a terminal state.
    func outcomeFeedback(_ status: SessionStatus)

    /// Feedback when the last kick is undone.
    func undoFeedback()
}
