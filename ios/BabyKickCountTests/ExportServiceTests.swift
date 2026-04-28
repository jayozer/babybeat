import XCTest
@testable import BabyKickCount

final class ExportServiceTests: XCTestCase {
    func testSummaryCSVIncludesOnlyTerminalSessionsAndEscapesNotes() {
        let complete = session(
            status: .complete,
            startedAt: Date(timeIntervalSince1970: 1_800_000_000),
            endedAt: Date(timeIntervalSince1970: 1_800_000_600),
            durationSec: 600,
            kickCount: 10,
            notes: "felt strong, then \"soft\"\nagain"
        )
        let active = session(status: .active, startedAt: Date(timeIntervalSince1970: 1_800_001_000))

        let csv = ExportService.summaryCSV(sessions: [complete, active])

        XCTAssertTrue(csv.hasPrefix("date,started_at,ended_at,duration_min,kick_count,target_count,status,strength_rating,notes"))
        XCTAssertTrue(csv.contains(",10.0,10,10,complete,"))
        XCTAssertTrue(csv.contains("\"felt strong, then \"\"soft\"\"\nagain\""))
        XCTAssertFalse(csv.contains("active"))
    }

    func testDetailedCSVSortsKickEventsByOrdinal() {
        let startedAt = Date(timeIntervalSince1970: 1_800_000_000)
        let firstKickAt = Date(timeIntervalSince1970: 1_800_000_010)
        let secondKickAt = Date(timeIntervalSince1970: 1_800_000_020)
        let complete = session(status: .complete, startedAt: startedAt, endedAt: secondKickAt, kickCount: 2)
        complete.events = [
            KickEvent(occurredAt: secondKickAt, ordinal: 2, source: .manualEdit, session: complete),
            KickEvent(occurredAt: firstKickAt, ordinal: 1, source: .tap, session: complete)
        ]

        let csv = ExportService.detailedCSV(sessions: [complete])
        let lines = csv.split(separator: "\n")

        XCTAssertEqual(lines.count, 3)
        XCTAssertTrue(lines[1].contains(",1,"))
        XCTAssertTrue(lines[1].hasSuffix(",tap"))
        XCTAssertTrue(lines[2].contains(",2,"))
        XCTAssertTrue(lines[2].hasSuffix(",manual_edit"))
    }

    func testExportableCountIgnoresNonTerminalSessions() {
        let sessions = [
            session(status: .complete),
            session(status: .endedEarly),
            session(status: .timeout),
            session(status: .active),
            session(status: .idle)
        ]

        XCTAssertEqual(ExportService.exportableCount(sessions: sessions), 3)
    }

    private func session(
        status: SessionStatus,
        startedAt: Date? = nil,
        endedAt: Date? = nil,
        durationSec: Double? = nil,
        kickCount: Int = 0,
        notes: String? = nil
    ) -> KickSession {
        let session = KickSession()
        session.status = status
        session.startedAt = startedAt
        session.endedAt = endedAt
        session.durationSec = durationSec
        session.kickCount = kickCount
        session.notes = notes
        return session
    }
}
