import Foundation
import SwiftData

@Model
final class KickSession {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var startedAt: Date?
    var endedAt: Date?
    var statusRaw: String
    var targetCount: Int
    var timeLimitSec: Int
    var kickCount: Int
    var durationSec: Double?
    var strengthRating: Int?
    var notes: String?
    var timezone: String
    var schemaVersion: Int
    var pausedDurationSec: Double
    var pausedAt: Date?

    @Relationship(deleteRule: .cascade, inverse: \KickEvent.session)
    var events: [KickEvent] = []

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        targetCount: Int = 10,
        timeLimitSec: Int = 7200
    ) {
        self.id = id
        self.createdAt = createdAt
        self.statusRaw = SessionStatus.idle.rawValue
        self.targetCount = targetCount
        self.timeLimitSec = timeLimitSec
        self.kickCount = 0
        self.timezone = TimeZone.current.identifier
        self.schemaVersion = 1
        self.pausedDurationSec = 0
    }

    var status: SessionStatus {
        get { SessionStatus(rawValue: statusRaw) ?? .idle }
        set { statusRaw = newValue.rawValue }
    }
}
