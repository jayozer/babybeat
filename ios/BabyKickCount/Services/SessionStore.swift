import Foundation
import SwiftData

/// SwiftData-backed store for sessions and kick events.
@MainActor
final class SessionStore {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - Sessions

    func createSession(targetCount: Int = 10, timeLimitSec: Int = 7200) throws -> KickSession {
        let session = KickSession(targetCount: targetCount, timeLimitSec: timeLimitSec)
        context.insert(session)
        try context.save()
        return session
    }

    func activeSession() throws -> KickSession? {
        let active = SessionStatus.active.rawValue
        let paused = SessionStatus.paused.rawValue
        let descriptor = FetchDescriptor<KickSession>(
            predicate: #Predicate { $0.statusRaw == active || $0.statusRaw == paused }
        )
        return try context.fetch(descriptor).first
    }

    func allSessions() throws -> [KickSession] {
        let descriptor = FetchDescriptor<KickSession>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func deleteSession(_ session: KickSession) throws {
        context.delete(session)
        try context.save()
    }

    func save() throws {
        try context.save()
    }

    // MARK: - Kicks

    @discardableResult
    func registerKick(in session: KickSession, source: KickSource = .tap) throws -> KickEvent {
        let ordinal = (session.events.map(\.ordinal).max() ?? 0) + 1
        let kick = KickEvent(ordinal: ordinal, source: source, session: session)
        context.insert(kick)
        session.kickCount = ordinal
        try context.save()
        return kick
    }

    @discardableResult
    func undoLastKick(in session: KickSession) throws -> KickEvent? {
        let sorted = session.events.sorted(by: { $0.ordinal < $1.ordinal })
        guard let last = sorted.last else { return nil }
        context.delete(last)
        session.kickCount = max(0, session.kickCount - 1)
        try context.save()
        return last
    }
}
