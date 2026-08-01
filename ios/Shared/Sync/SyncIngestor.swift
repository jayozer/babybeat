import Foundation
import SwiftData

/// Remembers kicks that were undone, so an event record arriving after its
/// tombstone does not resurrect the kick. Persisted in UserDefaults because
/// it must survive relaunch but is not part of the session history: entries
/// only matter while a session is open and are dropped when it ends.
struct KickTombstones {
    private static let key = "BabyKickCount.sync.kickTombstones"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    private var table: [String: [String]] {
        get { defaults.dictionary(forKey: Self.key) as? [String: [String]] ?? [:] }
        nonmutating set { defaults.set(newValue, forKey: Self.key) }
    }

    func contains(sessionID: UUID, eventID: UUID) -> Bool {
        table[sessionID.uuidString]?.contains(eventID.uuidString) ?? false
    }

    func insert(sessionID: UUID, eventID: UUID) {
        var current = table
        var events = current[sessionID.uuidString] ?? []
        guard !events.contains(eventID.uuidString) else { return }
        events.append(eventID.uuidString)
        current[sessionID.uuidString] = events
        table = current
    }

    func clear(sessionID: UUID) {
        var current = table
        guard current.removeValue(forKey: sessionID.uuidString) != nil else { return }
        table = current
    }
}

/// Applies incoming sync payloads to the local store. Every operation is
/// idempotent and order-independent: records upsert by UUID, kicks for a
/// session that has not arrived yet attach to a stub that the session upsert
/// later fills in, and ordinals/counts are recomputed from the event set
/// after every change.
@MainActor
final class SyncIngestor {
    private let context: ModelContext
    private let tombstones: KickTombstones

    init(context: ModelContext, tombstones: KickTombstones = KickTombstones()) {
        self.context = context
        self.tombstones = tombstones
    }

    /// Routes a durable envelope to the right handler. Snapshots are
    /// transient state owned by the sync services and are never persisted;
    /// commands and full-sync are phase 2.
    func ingest(_ envelope: SyncEnvelope) throws {
        switch envelope.type {
        case .sessionUpsert:
            try ingest(session: envelope.decode(SessionRecordDTO.self))
        case .kickBatch:
            try ingest(kicks: envelope.decode(KickBatchDTO.self).kicks)
        case .kickRemove:
            try ingest(removal: envelope.decode(KickRemoveDTO.self))
        case .snapshot, .command, .fullSyncRequest:
            break
        }
    }

    func ingest(session dto: SessionRecordDTO) throws {
        let session = try fetchSession(id: dto.id) ?? makeStub(id: dto.id)
        let incomingStatus = SessionStatus(rawValue: dto.statusRaw) ?? .idle

        // A terminal local record never regresses to a live state — a stale
        // or replayed upsert must not reopen a finished session.
        if !(session.status.isTerminal && !incomingStatus.isTerminal) {
            session.statusRaw = dto.statusRaw
            session.startedAt = dto.startedAt
            session.endedAt = dto.endedAt
            session.durationSec = dto.durationSec
            session.pausedDurationSec = dto.pausedDurationSec
            session.pausedAt = dto.pausedAt
        }
        session.createdAt = dto.createdAt
        session.targetCount = dto.targetCount
        session.timeLimitSec = dto.timeLimitSec
        session.timezone = dto.timezone
        session.schemaVersion = dto.schemaVersion

        // Rating and notes: an incoming nil never clobbers a local value.
        // Notes are only editable on the iPhone, so a watch record replayed
        // after the user typed notes must not erase them.
        if let rating = dto.strengthRating {
            session.strengthRating = rating
        }
        if let notes = dto.notes {
            session.notes = notes
        }

        recomputeKicks(for: session, fallbackCount: dto.kickCount)
        if session.status.isTerminal {
            tombstones.clear(sessionID: session.id)
        }
        try context.save()
    }

    func ingest(kicks: [KickRecordDTO]) throws {
        var touchedSessionIDs = Set<UUID>()
        for dto in kicks {
            guard !tombstones.contains(sessionID: dto.sessionID, eventID: dto.id),
                  try fetchEvent(id: dto.id) == nil else {
                continue
            }
            let session = try fetchSession(id: dto.sessionID) ?? makeStub(id: dto.sessionID)
            let event = KickEvent(
                id: dto.id,
                occurredAt: dto.occurredAt,
                ordinal: 0,
                source: KickSource(rawValue: dto.sourceRaw) ?? .tap,
                session: session
            )
            context.insert(event)
            touchedSessionIDs.insert(dto.sessionID)
        }
        for sessionID in touchedSessionIDs {
            if let session = try fetchSession(id: sessionID) {
                recomputeKicks(for: session, fallbackCount: nil)
            }
        }
        try context.save()
    }

    func ingest(removal dto: KickRemoveDTO) throws {
        let session = try fetchSession(id: dto.sessionID)
        // Only open sessions need the tombstone: a terminal session's event
        // set is final, and its tombstones have already been dropped.
        if session?.status.isTerminal != true {
            tombstones.insert(sessionID: dto.sessionID, eventID: dto.eventID)
        }
        if let event = try fetchEvent(id: dto.eventID) {
            context.delete(event)
        }
        if let session {
            // Relationship fix-up for a pending delete is only guaranteed at
            // save time, so `session.events` may still contain the deleted
            // event here — exclude it explicitly instead of trusting timing.
            let surviving = session.events.filter { $0.id != dto.eventID }
            session.kickCount = SessionMerge.renumber(surviving)
        }
        try context.save()
    }

    // MARK: - Private

    /// A placeholder for kicks that arrive before their session record.
    /// transferUserInfo delivery is FIFO so this is rare, but it makes the
    /// ingest order-independent; the session upsert fills the fields in.
    private func makeStub(id: UUID) -> KickSession {
        let stub = KickSession(id: id)
        context.insert(stub)
        return stub
    }

    private func recomputeKicks(for session: KickSession, fallbackCount: Int?) {
        if session.events.isEmpty {
            // No events yet (they may still be in transit) — trust the
            // record's own count until they arrive.
            if let fallbackCount {
                session.kickCount = fallbackCount
            } else {
                session.kickCount = 0
            }
            return
        }
        session.kickCount = SessionMerge.renumber(session.events)
    }

    private func fetchSession(id: UUID) throws -> KickSession? {
        let target = id
        let descriptor = FetchDescriptor<KickSession>(
            predicate: #Predicate { $0.id == target }
        )
        return try context.fetch(descriptor).first
    }

    private func fetchEvent(id: UUID) throws -> KickEvent? {
        let target = id
        let descriptor = FetchDescriptor<KickEvent>(
            predicate: #Predicate { $0.id == target }
        )
        return try context.fetch(descriptor).first
    }
}
