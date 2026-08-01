import AppIntents
import Foundation

/// Exposes finished sessions to the Shortcuts app, so a user can build
/// something like "Get last session from Littletaps → append to a note"
/// without any further work on our side.
struct SessionEntity: AppEntity, Identifiable {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Session"
    static let defaultQuery = SessionEntityQuery()

    let id: UUID

    @Property(title: "Movements")
    var kickCount: Int

    @Property(title: "Started")
    var startedAt: Date

    @Property(title: "Minutes")
    var minutes: Int

    @Property(title: "Outcome")
    var outcome: String

    init(id: UUID, kickCount: Int, startedAt: Date, minutes: Int, outcome: String) {
        self.id = id
        self.kickCount = kickCount
        self.startedAt = startedAt
        self.minutes = minutes
        self.outcome = outcome
    }

    @MainActor
    init(_ session: KickSession) {
        self.init(
            id: session.id,
            kickCount: session.kickCount,
            startedAt: session.startedAt ?? session.createdAt,
            minutes: Int(((session.durationSec ?? 0) / 60).rounded()),
            outcome: session.status.displayName
        )
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(kickCount) movements · \(minutes) min",
            subtitle: "\(startedAt.formatted(date: .abbreviated, time: .shortened))"
        )
    }
}

struct SessionEntityQuery: EntityQuery {
    @MainActor
    private func finishedSessions() throws -> [KickSession] {
        guard let viewModel = IntentBridge.session else {
            throw LittletapsIntentError.unavailable
        }
        return try viewModel.finishedSessions()
    }

    @MainActor
    func entities(for identifiers: [UUID]) throws -> [SessionEntity] {
        let wanted = Set(identifiers)
        return try finishedSessions()
            .filter { wanted.contains($0.id) }
            .map(SessionEntity.init)
    }

    @MainActor
    func suggestedEntities() throws -> [SessionEntity] {
        // `allSessions()` is already newest-first.
        try finishedSessions().prefix(10).map(SessionEntity.init)
    }
}
