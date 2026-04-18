import Foundation

enum SessionStatus: String, Codable, CaseIterable {
    case idle
    case active
    case paused
    case complete
    case timeout
    case endedEarly = "ended_early"

    var isTerminal: Bool {
        switch self {
        case .complete, .timeout, .endedEarly: return true
        default: return false
        }
    }

    var displayName: String {
        switch self {
        case .idle: return "Idle"
        case .active: return "Active"
        case .paused: return "Paused"
        case .complete: return "Complete"
        case .timeout: return "Timeout"
        case .endedEarly: return "Ended"
        }
    }
}

enum KickSource: String, Codable {
    case tap
    case manualEdit = "manual_edit"
}

enum SoundOption: String, Codable, CaseIterable, Identifiable {
    case softClick = "soft-click"
    case pop
    case heartbeat
    case bubble
    case none

    var id: String { rawValue }

    var label: String {
        switch self {
        case .softClick: return "Soft Click"
        case .pop: return "Pop"
        case .heartbeat: return "Heartbeat"
        case .bubble: return "Bubble"
        case .none: return "None"
        }
    }

    var desc: String {
        switch self {
        case .softClick: return "Gentle click sound"
        case .pop: return "Quick bright pop"
        case .heartbeat: return "Warm double thump"
        case .bubble: return "Soft rising tone"
        case .none: return "Silent mode"
        }
    }
}
