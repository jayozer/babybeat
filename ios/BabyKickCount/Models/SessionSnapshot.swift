import Foundation

/// A value copy of the parts of a `KickSession` that scheduling cares about.
///
/// `NotificationPlanner` has to run against something it can construct in a
/// unit test without a `ModelContainer`, and it must not hold a reference to a
/// SwiftData object it might read off the main actor. This is also the single
/// source of truth for the elapsed-time arithmetic — `SessionStateMachine`
/// delegates to it so the two can never drift.
struct SessionSnapshot: Equatable {
    let id: UUID
    let status: SessionStatus
    let startedAt: Date?
    let pausedAt: Date?
    let pausedDurationSec: Double
    let timeLimitSec: Int
    let kickCount: Int
    let targetCount: Int

    init(
        id: UUID,
        status: SessionStatus,
        startedAt: Date?,
        pausedAt: Date? = nil,
        pausedDurationSec: Double = 0,
        timeLimitSec: Int,
        kickCount: Int,
        targetCount: Int
    ) {
        self.id = id
        self.status = status
        self.startedAt = startedAt
        self.pausedAt = pausedAt
        self.pausedDurationSec = pausedDurationSec
        self.timeLimitSec = timeLimitSec
        self.kickCount = kickCount
        self.targetCount = targetCount
    }

    init(_ session: KickSession) {
        self.init(
            id: session.id,
            status: session.status,
            startedAt: session.startedAt,
            pausedAt: session.pausedAt,
            pausedDurationSec: session.pausedDurationSec,
            timeLimitSec: session.timeLimitSec,
            kickCount: session.kickCount,
            targetCount: session.targetCount
        )
    }

    /// Seconds elapsed since start, minus time spent paused.
    func elapsedSeconds(at now: Date = .now) -> Double {
        guard let startedAt else { return 0 }
        var elapsed = now.timeIntervalSince(startedAt) - pausedDurationSec
        if status == .paused, let pausedAt {
            elapsed -= now.timeIntervalSince(pausedAt)
        }
        return max(0, elapsed)
    }

    func remainingSeconds(at now: Date = .now) -> Double {
        max(0, Double(timeLimitSec) - elapsedSeconds(at: now))
    }
}
