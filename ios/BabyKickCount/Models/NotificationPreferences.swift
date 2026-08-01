import Foundation

/// Every reminder is opt-in. Nothing is scheduled until the user turns on
/// `masterEnabled`, and the inactivity nudge stays off even then until it is
/// chosen explicitly — see the copy rules in `NotificationPlanner`.
struct NotificationPreferences: Codable, Equatable {
    var masterEnabled: Bool = false

    var dailyEnabled: Bool = false
    /// Stored as components rather than a `Date`. A persisted `Date`
    /// re-interpreted after the user crosses a timezone would fire at the
    /// wrong wall-clock time, and `UNCalendarNotificationTrigger` wants
    /// components anyway.
    var dailyHour: Int = 20
    var dailyMinute: Int = 0
    /// `Calendar.weekday` values, 1 = Sunday.
    var dailyWeekdays: Set<Int> = [1, 2, 3, 4, 5, 6, 7]

    var sessionWindowEnabled: Bool = true
    /// 0 means "no pre-warning, only tell me when the window is up".
    var sessionWarningLeadMinutes: Int = 15

    var inactivityEnabled: Bool = false
    var inactivityThresholdDays: Int = 3

    /// Whether the one-time discovery card on the Counter screen has been shown.
    var hasSeenPrimer: Bool = false

    static let `default` = NotificationPreferences()

    static let warningLeadOptions = [0, 10, 15, 30]
    static let inactivityThresholdOptions = [2, 3, 5, 7]

    enum CodingKeys: String, CodingKey {
        case masterEnabled
        case dailyEnabled
        case dailyHour
        case dailyMinute
        case dailyWeekdays
        case sessionWindowEnabled
        case sessionWarningLeadMinutes
        case inactivityEnabled
        case inactivityThresholdDays
        case hasSeenPrimer
    }
}

/// Same forward-compatibility contract as `UserPreferences`: a key added by a
/// later build must not invalidate a blob written by an earlier one.
extension NotificationPreferences {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let fallback = NotificationPreferences.default

        masterEnabled = try container.decodeIfPresent(Bool.self, forKey: .masterEnabled)
            ?? fallback.masterEnabled
        dailyEnabled = try container.decodeIfPresent(Bool.self, forKey: .dailyEnabled)
            ?? fallback.dailyEnabled
        dailyHour = try container.decodeIfPresent(Int.self, forKey: .dailyHour)
            ?? fallback.dailyHour
        dailyMinute = try container.decodeIfPresent(Int.self, forKey: .dailyMinute)
            ?? fallback.dailyMinute
        dailyWeekdays = try container.decodeIfPresent(Set<Int>.self, forKey: .dailyWeekdays)
            ?? fallback.dailyWeekdays
        sessionWindowEnabled = try container.decodeIfPresent(Bool.self, forKey: .sessionWindowEnabled)
            ?? fallback.sessionWindowEnabled
        sessionWarningLeadMinutes = try container.decodeIfPresent(Int.self, forKey: .sessionWarningLeadMinutes)
            ?? fallback.sessionWarningLeadMinutes
        inactivityEnabled = try container.decodeIfPresent(Bool.self, forKey: .inactivityEnabled)
            ?? fallback.inactivityEnabled
        inactivityThresholdDays = try container.decodeIfPresent(Int.self, forKey: .inactivityThresholdDays)
            ?? fallback.inactivityThresholdDays
        hasSeenPrimer = try container.decodeIfPresent(Bool.self, forKey: .hasSeenPrimer)
            ?? fallback.hasSeenPrimer
    }
}
