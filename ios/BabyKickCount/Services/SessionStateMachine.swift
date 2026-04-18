import Foundation

enum SessionError: LocalizedError {
    case invalidTransition(from: SessionStatus, action: String)
    case missingTimestamp(String)

    var errorDescription: String? {
        switch self {
        case .invalidTransition(let from, let action):
            return "Cannot \(action) a session in \(from.displayName.lowercased()) state."
        case .missingTimestamp(let field):
            return "Missing \(field) timestamp."
        }
    }
}

enum SessionStateMachine {
    static func start(_ session: KickSession) throws {
        guard session.status == .idle else {
            throw SessionError.invalidTransition(from: session.status, action: "start")
        }
        session.status = .active
        session.startedAt = .now
    }

    static func pause(_ session: KickSession) throws {
        guard session.status == .active else {
            throw SessionError.invalidTransition(from: session.status, action: "pause")
        }
        session.status = .paused
        session.pausedAt = .now
    }

    static func resume(_ session: KickSession) throws {
        guard session.status == .paused else {
            throw SessionError.invalidTransition(from: session.status, action: "resume")
        }
        guard let pausedAt = session.pausedAt else {
            throw SessionError.missingTimestamp("pausedAt")
        }
        let additionalPaused = Date.now.timeIntervalSince(pausedAt)
        session.pausedDurationSec += additionalPaused
        session.pausedAt = nil
        session.status = .active
    }

    static func endEarly(_ session: KickSession) throws {
        guard session.status == .active || session.status == .paused else {
            throw SessionError.invalidTransition(from: session.status, action: "end")
        }
        let now = Date.now
        session.durationSec = duration(for: session, endingAt: now)
        session.endedAt = now
        session.status = .endedEarly
    }

    static func complete(_ session: KickSession) throws {
        guard session.status == .active else {
            throw SessionError.invalidTransition(from: session.status, action: "complete")
        }
        let now = Date.now
        session.durationSec = duration(for: session, endingAt: now)
        session.endedAt = now
        session.status = .complete
    }

    static func timeout(_ session: KickSession) throws {
        guard session.status == .active else {
            throw SessionError.invalidTransition(from: session.status, action: "timeout")
        }
        let now = Date.now
        session.durationSec = duration(for: session, endingAt: now)
        session.endedAt = now
        session.status = .timeout
    }

    /// Seconds elapsed since start, minus time spent paused.
    static func elapsedSeconds(for session: KickSession, at now: Date = .now) -> Double {
        guard let startedAt = session.startedAt else { return 0 }
        var elapsed = now.timeIntervalSince(startedAt) - session.pausedDurationSec
        if session.status == .paused, let pausedAt = session.pausedAt {
            elapsed -= now.timeIntervalSince(pausedAt)
        }
        return max(0, elapsed)
    }

    static func remainingSeconds(for session: KickSession, at now: Date = .now) -> Double {
        max(0, Double(session.timeLimitSec) - elapsedSeconds(for: session, at: now))
    }

    static func shouldTimeout(_ session: KickSession, at now: Date = .now) -> Bool {
        guard session.status == .active, session.startedAt != nil else { return false }
        return elapsedSeconds(for: session, at: now) >= Double(session.timeLimitSec)
    }

    static func shouldAutoComplete(_ session: KickSession) -> Bool {
        session.status == .active && session.kickCount >= session.targetCount
    }

    private static func duration(for session: KickSession, endingAt end: Date) -> Double {
        guard let startedAt = session.startedAt else { return 0 }
        var duration = end.timeIntervalSince(startedAt) - session.pausedDurationSec
        if session.status == .paused, let pausedAt = session.pausedAt {
            duration -= end.timeIntervalSince(pausedAt)
        }
        return max(0, duration)
    }
}
