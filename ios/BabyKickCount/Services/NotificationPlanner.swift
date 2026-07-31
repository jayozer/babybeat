import Foundation

/// Which piece of rendered artwork a notification carries. The renderer lands
/// with the polish pass; the planner only names the intent.
enum NotificationArtKind: String, Equatable {
    case heart
    case window
}

enum NotificationCategory {
    static let daily = "LT_DAILY"
    static let session = "LT_SESSION"
    static let quiet = "LT_QUIET"
}

enum NotificationAction {
    static let startCounting = "LT_START_COUNTING"
    static let snooze = "LT_SNOOZE"
    static let open = "LT_OPEN"
}

enum NotificationThread {
    static let reminders = "lt.reminders"
    static let session = "lt.session"
}

enum PlannedTrigger: Equatable {
    case calendar(DateComponents, repeats: Bool)
    case interval(TimeInterval)
}

enum PlannedLevel: Equatable {
    case passive
    case active
    case timeSensitive
}

struct PlannedNotification: Equatable {
    let id: String
    let title: String
    let subtitle: String?
    let body: String
    let trigger: PlannedTrigger
    let categoryID: String
    let threadID: String
    let level: PlannedLevel
    let relevance: Double
    let artKind: NotificationArtKind?
}

/// Decides *what* should be scheduled. Deliberately pure and framework-free,
/// mirroring `SessionStateMachine`: every entry point takes an injectable
/// `now`, so the whole scheduling story is unit-testable without a device.
/// `NotificationService` is the only thing that turns these into
/// `UNNotificationRequest`s.
enum NotificationPlanner {
    static let idPrefix = "lt."

    /// `UNTimeIntervalNotificationTrigger` rejects anything under a minute.
    /// Below this the user is about to see the result in-app anyway.
    static let minimumInterval: TimeInterval = 60

    /// The inactivity nudge is never allowed to land inside this range. The
    /// daily reminder is exempt because the user picked that time themselves.
    static let quietHoursStart = 22
    static let quietHoursEnd = 7
    static let quietHoursFallbackHour = 9

    static func plan(
        preferences: NotificationPreferences,
        authorized: Bool,
        session: SessionSnapshot?,
        lastSessionEndedAt: Date?,
        at now: Date,
        calendar: Calendar = .current
    ) -> [PlannedNotification] {
        guard authorized, preferences.masterEnabled else { return [] }

        var planned: [PlannedNotification] = []
        planned.append(contentsOf: dailyReminders(preferences: preferences))
        planned.append(contentsOf: sessionWindow(preferences: preferences, session: session, at: now))
        if let nudge = inactivityNudge(
            preferences: preferences,
            session: session,
            lastSessionEndedAt: lastSessionEndedAt,
            at: now,
            calendar: calendar
        ) {
            planned.append(nudge)
        }
        return planned
    }

    // MARK: - Daily

    /// One repeating weekly trigger per selected day.
    ///
    /// This is what keeps us clear of the 64-pending-request limit: a weekly
    /// repeating trigger occupies exactly one slot forever, so "days of week"
    /// costs at most 7 slots no matter how far out you look. Do **not**
    /// "optimise" this by enumerating future dates — that is how apps run out
    /// of slots and silently stop notifying.
    private static func dailyReminders(preferences: NotificationPreferences) -> [PlannedNotification] {
        guard preferences.dailyEnabled else { return [] }

        return preferences.dailyWeekdays.sorted()
            .filter { (1...7).contains($0) }
            .map { weekday in
                var components = DateComponents()
                components.hour = preferences.dailyHour
                components.minute = preferences.dailyMinute
                components.weekday = weekday

                return PlannedNotification(
                    id: "\(idPrefix)daily.\(weekday)",
                    title: "Time to count?",
                    subtitle: nil,
                    body: "Find a comfy spot and tap along with your little one.",
                    trigger: .calendar(components, repeats: true),
                    categoryID: NotificationCategory.daily,
                    threadID: NotificationThread.reminders,
                    level: .active,
                    relevance: 0.5,
                    artKind: .heart
                )
            }
    }

    // MARK: - Session window

    /// The in-app tick loop only runs in the foreground, so a backgrounded
    /// session's window closes with nothing to announce it. These two requests
    /// are the only thing that tells the user.
    ///
    /// Interval triggers, not calendar: the window is a *duration*, and a
    /// projected absolute date would be wrong across a DST boundary or a
    /// mid-session timezone change. Recomputing the remaining seconds on every
    /// reconcile keeps it accurate.
    private static func sessionWindow(
        preferences: NotificationPreferences,
        session: SessionSnapshot?,
        at now: Date
    ) -> [PlannedNotification] {
        guard preferences.sessionWindowEnabled,
              let session,
              session.status == .active else { return [] }

        let remaining = session.remainingSeconds(at: now)
        var planned: [PlannedNotification] = []

        let lead = TimeInterval(preferences.sessionWarningLeadMinutes * 60)
        if lead > 0 {
            let warnAfter = remaining - lead
            if warnAfter >= minimumInterval {
                planned.append(
                    PlannedNotification(
                        id: "\(idPrefix)session.warn.\(session.id.uuidString)",
                        title: "\(preferences.sessionWarningLeadMinutes) minutes left",
                        subtitle: "Your 2-hour window",
                        body: "Littletaps is still counting — open it to keep tapping.",
                        trigger: .interval(warnAfter),
                        categoryID: NotificationCategory.session,
                        threadID: NotificationThread.session,
                        level: .active,
                        relevance: 0.7,
                        artKind: .window
                    )
                )
            }
        }

        if remaining >= minimumInterval {
            planned.append(
                PlannedNotification(
                    id: "\(idPrefix)session.end.\(session.id.uuidString)",
                    title: "Your window is up",
                    subtitle: "2 hours",
                    body: "\(tapCount(session.kickCount)) so far. Open Littletaps to save this session.",
                    trigger: .interval(remaining),
                    categoryID: NotificationCategory.session,
                    threadID: NotificationThread.session,
                    level: .timeSensitive,
                    relevance: 1.0,
                    artKind: .window
                )
            )
        }

        return planned
    }

    // MARK: - Inactivity

    /// Fires at most once per quiet spell: the request is keyed to
    /// `lastSessionEndedAt`, and once its fire date is in the past we simply
    /// stop planning it rather than rolling it forward. Rolling it forward is
    /// what would turn a gentle nudge into a daily accusation.
    private static func inactivityNudge(
        preferences: NotificationPreferences,
        session: SessionSnapshot?,
        lastSessionEndedAt: Date?,
        at now: Date,
        calendar: Calendar
    ) -> PlannedNotification? {
        guard preferences.inactivityEnabled else { return nil }
        // Never nudge someone who is mid-session.
        if let session, session.status == .active || session.status == .paused { return nil }
        guard let lastSessionEndedAt else { return nil }

        guard var fire = calendar.date(
            byAdding: .day,
            value: preferences.inactivityThresholdDays,
            to: lastSessionEndedAt
        ) else { return nil }

        // Land it at the user's reminder hour rather than at whatever minute
        // they happened to finish a session.
        let hour = preferences.dailyEnabled ? preferences.dailyHour : 19
        let minute = preferences.dailyEnabled ? preferences.dailyMinute : 0
        fire = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: fire) ?? fire
        fire = shiftingOutOfQuietHours(fire, calendar: calendar)

        guard fire > now else { return nil }

        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fire)
        components.second = 0

        return PlannedNotification(
            id: "\(idPrefix)inactivity",
            title: "Ready when you are",
            subtitle: nil,
            // Never quantifies the gap. "It's been 3 days" reads as an
            // accusation in a domain where that lands hard.
            body: "It's been a little while since your last session. No rush.",
            trigger: .calendar(components, repeats: false),
            categoryID: NotificationCategory.quiet,
            threadID: NotificationThread.reminders,
            level: .passive,
            relevance: 0.1,
            artKind: .heart
        )
    }

    private static func shiftingOutOfQuietHours(_ date: Date, calendar: Calendar) -> Date {
        let hour = calendar.component(.hour, from: date)
        guard hour >= quietHoursStart || hour < quietHoursEnd else { return date }

        // Late evening rolls to the following morning; small hours stay on the
        // same calendar day.
        let base = hour >= quietHoursStart
            ? (calendar.date(byAdding: .day, value: 1, to: date) ?? date)
            : date
        return calendar.date(bySettingHour: quietHoursFallbackHour, minute: 0, second: 0, of: base) ?? date
    }

    // MARK: - Copy helpers

    /// States the count as a fact, never as a judgement. "You only counted 7"
    /// is exactly the phrasing this app must never ship.
    static func tapCount(_ count: Int) -> String {
        count == 1 ? "You counted 1 tap" : "You counted \(count) taps"
    }
}
