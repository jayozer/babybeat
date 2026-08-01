import Foundation

/// Wire protocol for iPhone <-> Apple Watch sync over WatchConnectivity.
///
/// Everything on the wire is a small Codable DTO wrapped in an envelope
/// dictionary `["t": type, "v": version, "d": property-list-encoded payload]`.
/// The transport never carries `@Model` objects; each device applies DTOs to
/// its own local store. No data leaves the user's paired devices — there is
/// no server on either end of this protocol.
enum SyncMessageType: String, Codable, CaseIterable {
    /// Latest whole-device state, sent via `updateApplicationContext`.
    /// Transient: it is never written to the store.
    case snapshot
    /// Full session record, sent via `transferUserInfo` (guaranteed queue).
    case sessionUpsert
    /// Append-only kick facts, sent via `transferUserInfo`.
    case kickBatch
    /// Tombstone for an undone kick.
    case kickRemove
    /// Remote lifecycle control (pause/resume/end). Reserved for phase 2.
    case command
    /// Ask the counterpart to resend everything. Reserved for phase 2.
    case fullSyncRequest
}

enum SyncDevice: String, Codable {
    case phone
    case watch
}

struct SyncEnvelope {
    static let currentVersion = 1

    private static let typeKey = "t"
    private static let versionKey = "v"
    private static let payloadKey = "d"

    let type: SyncMessageType
    let payload: Data

    init<T: Encodable>(_ type: SyncMessageType, payload: T) throws {
        self.type = type
        self.payload = try PropertyListEncoder().encode(payload)
    }

    /// Returns nil for malformed dictionaries, unknown message types, and
    /// messages from a future protocol version — all of which are ignored
    /// rather than treated as errors, so old and new app versions can coexist
    /// on a pair of devices.
    init?(dictionary: [String: Any]) {
        guard let rawType = dictionary[Self.typeKey] as? String,
              let type = SyncMessageType(rawValue: rawType),
              let version = dictionary[Self.versionKey] as? Int,
              version <= Self.currentVersion,
              let payload = dictionary[Self.payloadKey] as? Data else {
            return nil
        }
        self.type = type
        self.payload = payload
    }

    func dictionary() -> [String: Any] {
        [
            Self.typeKey: type.rawValue,
            Self.versionKey: Self.currentVersion,
            Self.payloadKey: payload
        ]
    }

    func decode<T: Decodable>(_ payloadType: T.Type) throws -> T {
        try PropertyListDecoder().decode(payloadType, from: payload)
    }
}

// MARK: - Payloads

/// Full mirror of a `KickSession`'s scalar fields.
struct SessionRecordDTO: Codable, Equatable {
    let id: UUID
    let createdAt: Date
    let startedAt: Date?
    let endedAt: Date?
    let statusRaw: String
    let targetCount: Int
    let timeLimitSec: Int
    let kickCount: Int
    let durationSec: Double?
    let strengthRating: Int?
    let notes: String?
    let timezone: String
    let schemaVersion: Int
    let pausedDurationSec: Double
    let pausedAt: Date?

    init(_ session: KickSession) {
        self.id = session.id
        self.createdAt = session.createdAt
        self.startedAt = session.startedAt
        self.endedAt = session.endedAt
        self.statusRaw = session.statusRaw
        self.targetCount = session.targetCount
        self.timeLimitSec = session.timeLimitSec
        self.kickCount = session.kickCount
        self.durationSec = session.durationSec
        self.strengthRating = session.strengthRating
        self.notes = session.notes
        self.timezone = session.timezone
        self.schemaVersion = session.schemaVersion
        self.pausedDurationSec = session.pausedDurationSec
        self.pausedAt = session.pausedAt
    }

    init(
        id: UUID,
        createdAt: Date,
        startedAt: Date?,
        endedAt: Date?,
        statusRaw: String,
        targetCount: Int,
        timeLimitSec: Int,
        kickCount: Int,
        durationSec: Double?,
        strengthRating: Int?,
        notes: String?,
        timezone: String,
        schemaVersion: Int,
        pausedDurationSec: Double,
        pausedAt: Date?
    ) {
        self.id = id
        self.createdAt = createdAt
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.statusRaw = statusRaw
        self.targetCount = targetCount
        self.timeLimitSec = timeLimitSec
        self.kickCount = kickCount
        self.durationSec = durationSec
        self.strengthRating = strengthRating
        self.notes = notes
        self.timezone = timezone
        self.schemaVersion = schemaVersion
        self.pausedDurationSec = pausedDurationSec
        self.pausedAt = pausedAt
    }
}

/// One kick. `ordinal` is intentionally absent: ordinals are derived on
/// ingest by sorting the session's events on `occurredAt`, so kicks logged on
/// two devices interleave correctly regardless of arrival order.
struct KickRecordDTO: Codable, Equatable {
    let id: UUID
    let sessionID: UUID
    let occurredAt: Date
    let sourceRaw: String

    init(id: UUID, sessionID: UUID, occurredAt: Date, sourceRaw: String) {
        self.id = id
        self.sessionID = sessionID
        self.occurredAt = occurredAt
        self.sourceRaw = sourceRaw
    }

    init(sessionID: UUID, event: KickEvent) {
        self.id = event.id
        self.sessionID = sessionID
        self.occurredAt = event.occurredAt
        self.sourceRaw = event.sourceRaw
    }
}

struct KickBatchDTO: Codable, Equatable {
    let kicks: [KickRecordDTO]
}

struct KickRemoveDTO: Codable, Equatable {
    let sessionID: UUID
    let eventID: UUID
}

/// The sender's current state. Used for live mirroring and for blocking a
/// second session from starting while the counterpart has one running.
struct SnapshotDTO: Codable, Equatable {
    /// Which device sent this — also the owner of `activeSession`, if any.
    let device: SyncDevice
    /// Per-device monotonic sequence number; stale snapshots are dropped.
    let seq: UInt64
    let activeSession: SessionRecordDTO?
    let liveKickCount: Int
    /// The sender's session defaults, so a session started on either device
    /// honors the settings configured on the iPhone.
    let defaultTargetCount: Int
    let defaultTimeLimitSec: Int
}

struct CommandDTO: Codable, Equatable {
    let sessionID: UUID
    let action: String
}

// MARK: - Snapshot staleness guard

/// Guards against out-of-order snapshot delivery within a process lifetime:
/// snapshots carry a per-device sequence number and this gate drops anything
/// not strictly newer than what has already been seen from that device. The
/// gate is deliberately not persisted — after a relaunch the system replays
/// the counterpart's *latest* application context, which is exactly the state
/// a fresh gate should admit.
struct SnapshotGate {
    private var lastSeq: [SyncDevice: UInt64] = [:]

    mutating func admit(_ snapshot: SnapshotDTO) -> Bool {
        if let last = lastSeq[snapshot.device], snapshot.seq <= last {
            return false
        }
        lastSeq[snapshot.device] = snapshot.seq
        return true
    }
}
