import ActivityKit
import Foundation

/// Starts, updates and ends the session Live Activity.
///
/// Everything here is best-effort: the user can disable Live Activities
/// system-wide or per app, and a session must keep working exactly as before
/// when they have. Failures are swallowed the way `FeedbackService` swallows
/// audio failures.
@MainActor
enum LiveActivityController {
    private static var current: Activity<KickSessionAttributes>?

    private static var isAvailable: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    /// Single entry point, driven from the same lifecycle hooks as
    /// notification scheduling. Idempotent: safe to call on every transition.
    static func sync(with snapshot: SessionSnapshot?, at now: Date = .now) {
        guard let snapshot, snapshot.status == .active || snapshot.status == .paused else {
            end()
            return
        }
        guard isAvailable else { return }

        let state = KickSessionAttributes.ContentState(
            kickCount: snapshot.kickCount,
            targetCount: snapshot.targetCount,
            windowEnd: now.addingTimeInterval(snapshot.remainingSeconds(at: now)),
            isPaused: snapshot.status == .paused
        )

        if let activity = current, activity.attributes.sessionID == snapshot.id {
            Task { await activity.update(ActivityContent(state: state, staleDate: nil)) }
            return
        }

        // A different session means the previous activity is stale.
        end()

        current = try? Activity.request(
            attributes: KickSessionAttributes(sessionID: snapshot.id),
            content: ActivityContent(state: state, staleDate: nil)
        )
    }

    static func end() {
        guard let activity = current else { return }
        current = nil
        Task { await activity.end(nil, dismissalPolicy: .immediate) }
    }

    /// Reattaches to an activity that outlived the app process, so a relaunch
    /// updates the existing one instead of starting a second.
    static func adopt(matching snapshot: SessionSnapshot?) {
        guard current == nil else { return }
        current = Activity<KickSessionAttributes>.activities.first {
            $0.attributes.sessionID == snapshot?.id
        }
        // Anything left over from a session that is no longer running.
        for orphan in Activity<KickSessionAttributes>.activities
        where orphan.attributes.sessionID != snapshot?.id {
            Task { await orphan.end(nil, dismissalPolicy: .immediate) }
        }
    }
}
