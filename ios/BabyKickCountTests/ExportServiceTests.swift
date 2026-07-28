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

    /// Escaping the fields correctly is not the same as the file staying aligned
    /// once a spreadsheet reads it back. Parse the output with an RFC 4180
    /// reader and assert every row still has exactly one field per column, even
    /// when a note contains a comma, a double quote, and a newline.
    func testSummaryCSVRoundTripsWithoutBreakingColumnAlignment() {
        let awkwardNotes = "felt strong, then \"soft\"\nagain"
        let first = session(
            status: .complete,
            startedAt: Date(timeIntervalSince1970: 1_800_000_000),
            endedAt: Date(timeIntervalSince1970: 1_800_000_600),
            durationSec: 600,
            kickCount: 10,
            notes: awkwardNotes
        )
        let second = session(
            status: .endedEarly,
            startedAt: Date(timeIntervalSince1970: 1_800_100_000),
            endedAt: Date(timeIntervalSince1970: 1_800_100_300),
            durationSec: 300,
            kickCount: 4,
            notes: "quiet evening"
        )

        let rows = parseCSV(ExportService.summaryCSV(sessions: [first, second]))

        XCTAssertEqual(rows.count, 3, "header plus two sessions")
        let columnCount = rows[0].count
        XCTAssertEqual(columnCount, 9)
        for (index, row) in rows.enumerated() {
            XCTAssertEqual(row.count, columnCount, "row \(index) has the wrong number of fields")
        }

        // The embedded newline must survive as data, not split the row.
        XCTAssertEqual(rows[1][8], awkwardNotes)
        XCTAssertEqual(rows[1][4], "10")
        XCTAssertEqual(rows[1][6], "complete")
        XCTAssertEqual(rows[2][8], "quiet evening")
        XCTAssertEqual(rows[2][6], "ended_early")
    }

    /// Minimal RFC 4180 reader: quoted fields may contain commas and newlines,
    /// and a doubled quote inside a quoted field is a literal quote.
    private func parseCSV(_ text: String) -> [[String]] {
        var rows: [[String]] = []
        var row: [String] = []
        var field = ""
        var insideQuotes = false
        var iterator = text.makeIterator()
        var pending: Character?

        while let character = pending ?? iterator.next() {
            pending = nil

            if insideQuotes {
                if character == "\"" {
                    if let next = iterator.next() {
                        if next == "\"" {
                            field.append("\"")
                        } else {
                            insideQuotes = false
                            pending = next
                        }
                    } else {
                        insideQuotes = false
                    }
                } else {
                    field.append(character)
                }
                continue
            }

            switch character {
            case "\"":
                insideQuotes = true
            case ",":
                row.append(field)
                field = ""
            case "\n":
                row.append(field)
                field = ""
                rows.append(row)
                row = []
            default:
                field.append(character)
            }
        }

        if !field.isEmpty || !row.isEmpty {
            row.append(field)
            rows.append(row)
        }
        return rows
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
