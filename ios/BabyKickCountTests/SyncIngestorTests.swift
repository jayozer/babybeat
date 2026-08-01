import XCTest
import SwiftData
@testable import BabyKickCount

@MainActor
final class SyncIngestorTests: XCTestCase {
    private struct Fixture {
        let container: ModelContainer
        let context: ModelContext
        let ingestor: SyncIngestor
    }

    private func makeFixture() throws -> Fixture {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: KickSession.self, KickEvent.self,
            configurations: config
        )
        // Each fixture gets its own defaults suite so tombstones from one
        // test can never leak into another.
        let defaults = UserDefaults(suiteName: "SyncIngestorTests-\(UUID().uuidString)")!
        let context = container.mainContext
        let ingestor = SyncIngestor(
            context: context,
            tombstones: KickTombstones(defaults: defaults)
        )
        return Fixture(container: container, context: context, ingestor: ingestor)
    }

    private func makeRecord(
        id: UUID,
        statusRaw: String = SessionStatus.complete.rawValue,
        kickCount: Int = 2,
        rating: Int? = nil,
        notes: String? = nil
    ) -> SessionRecordDTO {
        SessionRecordDTO(
            id: id,
            createdAt: Date(timeIntervalSince1970: 1_000),
            startedAt: Date(timeIntervalSince1970: 1_010),
            endedAt: Date(timeIntervalSince1970: 2_000),
            statusRaw: statusRaw,
            targetCount: 10,
            timeLimitSec: 7_200,
            kickCount: kickCount,
            durationSec: 990,
            strengthRating: rating,
            notes: notes,
            timezone: "America/Los_Angeles",
            schemaVersion: 1,
            pausedDurationSec: 0,
            pausedAt: nil
        )
    }

    private func makeKick(
        id: UUID = UUID(),
        sessionID: UUID,
        at seconds: Double
    ) -> KickRecordDTO {
        KickRecordDTO(
            id: id,
            sessionID: sessionID,
            occurredAt: Date(timeIntervalSince1970: seconds),
            sourceRaw: KickSource.tap.rawValue
        )
    }

    private func fetchSession(id: UUID, in context: ModelContext) throws -> KickSession? {
        let target = id
        let descriptor = FetchDescriptor<KickSession>(
            predicate: #Predicate { $0.id == target }
        )
        return try context.fetch(descriptor).first
    }

    // MARK: - Sessions

    func testUpsertCreatesOnceAndUpdatesInPlace() throws {
        let fixture = try makeFixture()
        let id = UUID()

        try fixture.ingestor.ingest(session: makeRecord(id: id, rating: nil))
        try fixture.ingestor.ingest(session: makeRecord(id: id, rating: 4))

        let all = try fixture.context.fetch(FetchDescriptor<KickSession>())
        XCTAssertEqual(all.count, 1, "upsert by UUID must never duplicate")
        XCTAssertEqual(all.first?.strengthRating, 4)
        XCTAssertEqual(all.first?.status, .complete)
    }

    func testUpsertWithoutEventsTrustsTheRecordCount() throws {
        let fixture = try makeFixture()
        let id = UUID()

        try fixture.ingestor.ingest(session: makeRecord(id: id, kickCount: 10))

        let session = try XCTUnwrap(fetchSession(id: id, in: fixture.context))
        XCTAssertEqual(session.kickCount, 10, "events may still be in transit")
    }

    func testTerminalSessionNeverRegressesToALiveState() throws {
        let fixture = try makeFixture()
        let id = UUID()
        try fixture.ingestor.ingest(session: makeRecord(id: id))

        try fixture.ingestor.ingest(
            session: makeRecord(id: id, statusRaw: SessionStatus.active.rawValue)
        )

        let session = try XCTUnwrap(fetchSession(id: id, in: fixture.context))
        XCTAssertEqual(session.status, .complete, "a replayed live record must not reopen it")
    }

    func testIncomingNilRatingAndNotesKeepLocalValues() throws {
        let fixture = try makeFixture()
        let id = UUID()
        try fixture.ingestor.ingest(session: makeRecord(id: id))
        let session = try XCTUnwrap(fetchSession(id: id, in: fixture.context))
        session.strengthRating = 5
        session.notes = "typed on the phone"

        try fixture.ingestor.ingest(session: makeRecord(id: id, rating: nil, notes: nil))

        XCTAssertEqual(session.strengthRating, 5)
        XCTAssertEqual(session.notes, "typed on the phone")
    }

    // MARK: - Kicks

    func testKicksArrivingBeforeTheirSessionAttachToAStubTheUpsertFillsIn() throws {
        let fixture = try makeFixture()
        let id = UUID()

        try fixture.ingestor.ingest(kicks: [
            makeKick(sessionID: id, at: 1_100),
            makeKick(sessionID: id, at: 1_200)
        ])
        try fixture.ingestor.ingest(session: makeRecord(id: id))

        let session = try XCTUnwrap(fetchSession(id: id, in: fixture.context))
        XCTAssertEqual(session.events.count, 2)
        XCTAssertEqual(session.kickCount, 2)
        XCTAssertEqual(session.status, .complete)
    }

    func testDuplicateKickDeliveryIsIgnored() throws {
        let fixture = try makeFixture()
        let sessionID = UUID()
        let kick = makeKick(sessionID: sessionID, at: 1_100)
        try fixture.ingestor.ingest(session: makeRecord(id: sessionID))

        try fixture.ingestor.ingest(kicks: [kick])
        try fixture.ingestor.ingest(kicks: [kick])

        let session = try XCTUnwrap(fetchSession(id: sessionID, in: fixture.context))
        XCTAssertEqual(session.events.count, 1)
        XCTAssertEqual(session.kickCount, 1)
    }

    func testOrdinalsDeriveFromOccurredAtAcrossBatches() throws {
        let fixture = try makeFixture()
        let sessionID = UUID()
        try fixture.ingestor.ingest(session: makeRecord(id: sessionID))

        // Later kick arrives first; ordinals must still follow the clock.
        try fixture.ingestor.ingest(kicks: [makeKick(sessionID: sessionID, at: 1_300)])
        try fixture.ingestor.ingest(kicks: [makeKick(sessionID: sessionID, at: 1_100)])

        let session = try XCTUnwrap(fetchSession(id: sessionID, in: fixture.context))
        let ordered = session.events.sorted { $0.ordinal < $1.ordinal }
        XCTAssertEqual(ordered.map(\.ordinal), [1, 2])
        XCTAssertEqual(
            ordered.map { $0.occurredAt.timeIntervalSince1970 },
            [1_100, 1_300]
        )
    }

    // MARK: - Undo tombstones

    func testTombstoneBeforeEventPreventsResurrection() throws {
        let fixture = try makeFixture()
        let sessionID = UUID()
        let kick = makeKick(sessionID: sessionID, at: 1_100)

        try fixture.ingestor.ingest(
            removal: KickRemoveDTO(sessionID: sessionID, eventID: kick.id)
        )
        try fixture.ingestor.ingest(kicks: [kick])

        let session = try fetchSession(id: sessionID, in: fixture.context)
        XCTAssertEqual(session?.events.count ?? 0, 0, "an undone kick must stay undone")
    }

    func testRemovalDeletesTheKickAndRecomputes() throws {
        let fixture = try makeFixture()
        let sessionID = UUID()
        let first = makeKick(sessionID: sessionID, at: 1_100)
        let second = makeKick(sessionID: sessionID, at: 1_200)
        try fixture.ingestor.ingest(
            session: makeRecord(id: sessionID, statusRaw: SessionStatus.active.rawValue)
        )
        try fixture.ingestor.ingest(kicks: [first, second])

        try fixture.ingestor.ingest(
            removal: KickRemoveDTO(sessionID: sessionID, eventID: second.id)
        )

        let session = try XCTUnwrap(fetchSession(id: sessionID, in: fixture.context))
        XCTAssertEqual(session.events.count, 1)
        XCTAssertEqual(session.kickCount, 1)
        XCTAssertEqual(session.events.first?.ordinal, 1)
    }

    // MARK: - Envelope routing

    func testEnvelopeRoutingAppliesADurableRecord() throws {
        let fixture = try makeFixture()
        let id = UUID()
        let envelope = try SyncEnvelope(.sessionUpsert, payload: makeRecord(id: id))

        try fixture.ingestor.ingest(envelope)

        XCTAssertNotNil(try fetchSession(id: id, in: fixture.context))
    }

    func testSnapshotEnvelopesAreNeverPersisted() throws {
        let fixture = try makeFixture()
        let snapshot = SnapshotDTO(
            device: .watch,
            seq: 1,
            activeSession: makeRecord(id: UUID(), statusRaw: SessionStatus.active.rawValue),
            liveKickCount: 3,
            defaultTargetCount: 10,
            defaultTimeLimitSec: 7_200
        )
        let envelope = try SyncEnvelope(.snapshot, payload: snapshot)

        try fixture.ingestor.ingest(envelope)

        let all = try fixture.context.fetch(FetchDescriptor<KickSession>())
        XCTAssertTrue(all.isEmpty, "snapshots are transient state, not history")
    }
}
