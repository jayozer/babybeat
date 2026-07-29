import Foundation

enum ExportService {
    /// Summary CSV: one row per completed/timeout/ended-early session.
    static func summaryCSV(sessions: [KickSession]) -> String {
        var lines = ["date,started_at,ended_at,duration_min,kick_count,target_count,status,strength_rating,notes"]
        let formatter = ISO8601DateFormatter()
        for session in sessions where session.status.isTerminal {
            let started = session.startedAt.map(formatter.string(from:)) ?? ""
            let ended = session.endedAt.map(formatter.string(from:)) ?? ""
            let durationMin = session.durationSec.map { String(format: "%.1f", $0 / 60) } ?? ""
            let rating = session.strengthRating.map(String.init) ?? ""
            let notes = escape(session.notes ?? "")
            let dayString = session.startedAt.map { day($0) } ?? ""
            lines.append("\(dayString),\(started),\(ended),\(durationMin),\(session.kickCount),\(session.targetCount),\(session.status.rawValue),\(rating),\(notes)")
        }
        return lines.joined(separator: "\n")
    }

    /// Detailed CSV: one row per individual kick event.
    static func detailedCSV(sessions: [KickSession]) -> String {
        var lines = ["session_id,session_started_at,kick_ordinal,kick_occurred_at,source"]
        let formatter = ISO8601DateFormatter()
        for session in sessions where session.status.isTerminal {
            let started = session.startedAt.map(formatter.string(from:)) ?? ""
            for event in session.events.sorted(by: { $0.ordinal < $1.ordinal }) {
                let when = formatter.string(from: event.occurredAt)
                lines.append("\(session.id.uuidString),\(started),\(event.ordinal),\(when),\(event.source.rawValue)")
            }
        }
        return lines.joined(separator: "\n")
    }

    static func exportableCount(sessions: [KickSession]) -> Int {
        sessions.filter { $0.status.isTerminal }.count
    }

    private static func day(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    /// Characters that make Excel, Numbers and Sheets read a cell as a formula
    /// rather than text. Tab and carriage return are included because those
    /// apps strip leading whitespace first and then see the character beneath.
    private static let formulaTriggers: Set<Character> = ["=", "+", "-", "@", "\t", "\r"]

    private static func escape(_ value: String) -> String {
        var value = value

        // A note like "- strong kicks tonight" is read as a formula and renders
        // as #NAME?; a crafted one can invoke a spreadsheet function when the
        // export is opened. A leading apostrophe marks the cell as literal text.
        if let first = value.first, formulaTriggers.contains(first) {
            value = "'" + value
        }

        guard value.contains(",") || value.contains("\"")
            || value.contains("\n") || value.contains("\r") else { return value }
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }
}
