import XCTest
@testable import BabyKickCount

final class SyncMessageCodingTests: XCTestCase {
    private func makeRecord(
        id: UUID = UUID(),
        notes: String? = nil,
        rating: Int? = nil
    ) -> SessionRecordDTO {
        SessionRecordDTO(
            id: id,
            createdAt: Date(timeIntervalSince1970: 1_000),
            startedAt: Date(timeIntervalSince1970: 1_010),
            endedAt: Date(timeIntervalSince1970: 2_000),
            statusRaw: SessionStatus.complete.rawValue,
            targetCount: 10,
            timeLimitSec: 7_200,
            kickCount: 10,
            durationSec: 990,
            strengthRating: rating,
            notes: notes,
            timezone: "America/Los_Angeles",
            schemaVersion: 1,
            pausedDurationSec: 0,
            pausedAt: nil
        )
    }

    func testEnvelopeRoundTripsThroughTheWireDictionary() throws {
        let record = makeRecord(notes: "strong evening kicks", rating: 4)
        let envelope = try SyncEnvelope(.sessionUpsert, payload: record)

        let received = SyncEnvelope(dictionary: envelope.dictionary())

        XCTAssertNotNil(received)
        XCTAssertEqual(received?.type, .sessionUpsert)
        XCTAssertEqual(try received?.decode(SessionRecordDTO.self), record)
    }

    func testOptionalFieldsSurviveTheRoundTripAsNil() throws {
        let record = makeRecord(notes: nil, rating: nil)
        let envelope = try SyncEnvelope(.sessionUpsert, payload: record)

        let decoded = try XCTUnwrap(SyncEnvelope(dictionary: envelope.dictionary()))
            .decode(SessionRecordDTO.self)

        XCTAssertNil(decoded.notes)
        XCTAssertNil(decoded.strengthRating)
        XCTAssertNil(decoded.pausedAt)
    }

    func testSnapshotRoundTripsWithoutAnActiveSession() throws {
        let snapshot = SnapshotDTO(
            device: .watch,
            seq: 7,
            activeSession: nil,
            liveKickCount: 0,
            defaultTargetCount: 10,
            defaultTimeLimitSec: 7_200
        )
        let envelope = try SyncEnvelope(.snapshot, payload: snapshot)

        let decoded = try XCTUnwrap(SyncEnvelope(dictionary: envelope.dictionary()))
            .decode(SnapshotDTO.self)

        XCTAssertEqual(decoded, snapshot)
    }

    func testKickBatchRoundTrips() throws {
        let sessionID = UUID()
        let batch = KickBatchDTO(kicks: [
            KickRecordDTO(
                id: UUID(),
                sessionID: sessionID,
                occurredAt: Date(timeIntervalSince1970: 1_100),
                sourceRaw: KickSource.tap.rawValue
            ),
            KickRecordDTO(
                id: UUID(),
                sessionID: sessionID,
                occurredAt: Date(timeIntervalSince1970: 1_160),
                sourceRaw: KickSource.tap.rawValue
            )
        ])
        let envelope = try SyncEnvelope(.kickBatch, payload: batch)

        let decoded = try XCTUnwrap(SyncEnvelope(dictionary: envelope.dictionary()))
            .decode(KickBatchDTO.self)

        XCTAssertEqual(decoded, batch)
    }

    func testMalformedDictionariesAreRejected() {
        XCTAssertNil(SyncEnvelope(dictionary: [:]))
        XCTAssertNil(SyncEnvelope(dictionary: ["t": "snapshot", "v": 1]))
        XCTAssertNil(SyncEnvelope(dictionary: ["t": "snapshot", "d": Data()]))
    }

    func testUnknownMessageTypeIsRejected() {
        let dictionary: [String: Any] = ["t": "telemetry", "v": 1, "d": Data()]

        XCTAssertNil(SyncEnvelope(dictionary: dictionary))
    }

    func testFutureProtocolVersionIsRejected() {
        let dictionary: [String: Any] = [
            "t": "snapshot",
            "v": SyncEnvelope.currentVersion + 1,
            "d": Data()
        ]

        XCTAssertNil(SyncEnvelope(dictionary: dictionary))
    }

    func testSnapshotGateDropsStaleAndReplayedSnapshots() {
        var gate = SnapshotGate()
        let first = SnapshotDTO(
            device: .watch, seq: 1, activeSession: nil,
            liveKickCount: 0, defaultTargetCount: 10, defaultTimeLimitSec: 7_200
        )
        let second = SnapshotDTO(
            device: .watch, seq: 2, activeSession: nil,
            liveKickCount: 0, defaultTargetCount: 10, defaultTimeLimitSec: 7_200
        )

        XCTAssertTrue(gate.admit(first))
        XCTAssertTrue(gate.admit(second))
        XCTAssertFalse(gate.admit(second), "replayed snapshot must be dropped")
        XCTAssertFalse(gate.admit(first), "stale snapshot must be dropped")
    }

    func testSnapshotGateTracksDevicesIndependently() {
        var gate = SnapshotGate()
        let watch = SnapshotDTO(
            device: .watch, seq: 5, activeSession: nil,
            liveKickCount: 0, defaultTargetCount: 10, defaultTimeLimitSec: 7_200
        )
        let phone = SnapshotDTO(
            device: .phone, seq: 1, activeSession: nil,
            liveKickCount: 0, defaultTargetCount: 10, defaultTimeLimitSec: 7_200
        )

        XCTAssertTrue(gate.admit(watch))
        XCTAssertTrue(gate.admit(phone), "a lower seq from the other device is not stale")
    }
}
