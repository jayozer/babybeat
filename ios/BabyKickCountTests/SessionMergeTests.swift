import XCTest
@testable import BabyKickCount

final class SessionMergeTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 10_000)

    private func candidate(
        id: UUID = UUID(),
        startedAt: Double?,
        endedAt: Double?,
        isTerminal: Bool
    ) -> SessionMergeCandidate {
        SessionMergeCandidate(
            id: id,
            startedAt: startedAt.map(Date.init(timeIntervalSince1970:)),
            endedAt: endedAt.map(Date.init(timeIntervalSince1970:)),
            isTerminal: isTerminal
        )
    }

    // MARK: - Conflict detection

    func testOverlappingLiveSessionsConflict() {
        let phone = candidate(startedAt: 1_000, endedAt: nil, isTerminal: false)
        let watch = candidate(startedAt: 1_500, endedAt: nil, isTerminal: false)

        XCTAssertTrue(SessionMerge.conflict(phone, watch, at: now))
        XCTAssertTrue(SessionMerge.conflict(watch, phone, at: now), "conflict must be symmetric")
    }

    func testLiveSessionOverlappingATerminalOneConflicts() {
        let finished = candidate(startedAt: 1_000, endedAt: 2_000, isTerminal: true)
        let live = candidate(startedAt: 1_500, endedAt: nil, isTerminal: false)

        XCTAssertTrue(SessionMerge.conflict(finished, live, at: now))
    }

    func testTwoTerminalSessionsNeverConflict() {
        let a = candidate(startedAt: 1_000, endedAt: 2_000, isTerminal: true)
        let b = candidate(startedAt: 1_500, endedAt: 2_500, isTerminal: true)

        XCTAssertFalse(
            SessionMerge.conflict(a, b, at: now),
            "both records are finished history; merging would double-count"
        )
    }

    func testDisjointWindowsDoNotConflict() {
        let earlier = candidate(startedAt: 1_000, endedAt: 2_000, isTerminal: true)
        let later = candidate(startedAt: 3_000, endedAt: nil, isTerminal: false)

        XCTAssertFalse(SessionMerge.conflict(earlier, later, at: now))
    }

    func testUnstartedSessionsDoNotConflict() {
        let idle = candidate(startedAt: nil, endedAt: nil, isTerminal: false)
        let live = candidate(startedAt: 1_000, endedAt: nil, isTerminal: false)

        XCTAssertFalse(SessionMerge.conflict(idle, live, at: now))
    }

    func testASessionNeverConflictsWithItself() {
        let id = UUID()
        let a = candidate(id: id, startedAt: 1_000, endedAt: nil, isTerminal: false)
        let b = candidate(id: id, startedAt: 1_000, endedAt: nil, isTerminal: false)

        XCTAssertFalse(SessionMerge.conflict(a, b, at: now))
    }

    // MARK: - Survivor selection

    func testEarlierStartSurvives() {
        let earlier = candidate(startedAt: 1_000, endedAt: nil, isTerminal: false)
        let later = candidate(startedAt: 1_500, endedAt: nil, isTerminal: false)

        XCTAssertEqual(SessionMerge.survivorID(earlier, later), earlier.id)
        XCTAssertEqual(
            SessionMerge.survivorID(later, earlier), earlier.id,
            "survivor must not depend on argument order"
        )
    }

    func testTieBreaksOnLexicographicallySmallerID() {
        let idA = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let idB = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let a = candidate(id: idA, startedAt: 1_000, endedAt: nil, isTerminal: false)
        let b = candidate(id: idB, startedAt: 1_000, endedAt: nil, isTerminal: false)

        XCTAssertEqual(SessionMerge.survivorID(a, b), idA)
        XCTAssertEqual(SessionMerge.survivorID(b, a), idA)
    }

    func testStartedSessionBeatsUnstartedOne() {
        let started = candidate(startedAt: 1_000, endedAt: nil, isTerminal: false)
        let unstarted = candidate(startedAt: nil, endedAt: nil, isTerminal: false)

        XCTAssertEqual(SessionMerge.survivorID(started, unstarted), started.id)
        XCTAssertEqual(SessionMerge.survivorID(unstarted, started), started.id)
    }

    // MARK: - Ordinal renumbering

    func testRenumberSortsByOccurredAtAndReturnsCount() {
        let first = KickEvent(occurredAt: Date(timeIntervalSince1970: 100), ordinal: 9)
        let second = KickEvent(occurredAt: Date(timeIntervalSince1970: 200), ordinal: 1)
        let third = KickEvent(occurredAt: Date(timeIntervalSince1970: 300), ordinal: 5)

        let count = SessionMerge.renumber([third, first, second])

        XCTAssertEqual(count, 3)
        XCTAssertEqual(first.ordinal, 1)
        XCTAssertEqual(second.ordinal, 2)
        XCTAssertEqual(third.ordinal, 3)
    }

    func testRenumberBreaksTimestampTiesByID() {
        let at = Date(timeIntervalSince1970: 100)
        let idA = UUID(uuidString: "00000000-0000-0000-0000-00000000000A")!
        let idB = UUID(uuidString: "00000000-0000-0000-0000-00000000000B")!
        let a = KickEvent(id: idA, occurredAt: at, ordinal: 0)
        let b = KickEvent(id: idB, occurredAt: at, ordinal: 0)

        SessionMerge.renumber([b, a])

        XCTAssertEqual(a.ordinal, 1)
        XCTAssertEqual(b.ordinal, 2)
    }
}
