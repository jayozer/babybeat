import XCTest
@testable import BabyKickCount

final class NotificationPlannerTests: XCTestCase {
    /// Pinned so the quiet-hours and weekday assertions do not depend on where
    /// the test happens to run.
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        return calendar
    }()

    /// Wednesday 10 June 2026, 10:00 — deliberately nowhere near a DST change.
    private var now: Date {
        calendar.date(from: DateComponents(year: 2026, month: 6, day: 10, hour: 10, minute: 0))!
    }

    private func enabledPreferences() -> NotificationPreferences {
        var preferences = NotificationPreferences.default
        preferences.masterEnabled = true
        return preferences
    }

    private func activeSession(remaining: TimeInterval, kickCount: Int = 0) -> SessionSnapshot {
        let limit = 7200
        return SessionSnapshot(
            id: UUID(),
            status: .active,
            startedAt: now.addingTimeInterval(-(Double(limit) - remaining)),
            timeLimitSec: limit,
            kickCount: kickCount,
            targetCount: 10
        )
    }

    private func plan(
        _ preferences: NotificationPreferences,
        authorized: Bool = true,
        session: SessionSnapshot? = nil,
        lastSessionEndedAt: Date? = nil
    ) -> [PlannedNotification] {
        NotificationPlanner.plan(
            preferences: preferences,
            authorized: authorized,
            session: session,
            lastSessionEndedAt: lastSessionEndedAt,
            at: now,
            calendar: calendar
        )
    }

    // MARK: - Gates

    func testPlansNothingWhenMasterSwitchIsOff() {
        var preferences = NotificationPreferences.default
        preferences.dailyEnabled = true
        preferences.sessionWindowEnabled = true

        XCTAssertTrue(plan(preferences, session: activeSession(remaining: 3600)).isEmpty)
    }

    func testPlansNothingWhenNotAuthorized() {
        var preferences = enabledPreferences()
        preferences.dailyEnabled = true

        XCTAssertTrue(plan(preferences, authorized: false).isEmpty)
    }

    // MARK: - Daily

    func testDailyReminderSchedulesOneRepeatingRequestPerSelectedWeekday() {
        var preferences = enabledPreferences()
        preferences.dailyEnabled = true
        preferences.dailyWeekdays = [2, 4, 6]
        preferences.dailyHour = 20
        preferences.dailyMinute = 30

        let planned = plan(preferences)

        XCTAssertEqual(planned.map(\.id), ["lt.daily.2", "lt.daily.4", "lt.daily.6"])
        for (item, weekday) in zip(planned, [2, 4, 6]) {
            guard case .calendar(let components, let repeats) = item.trigger else {
                return XCTFail("Expected a calendar trigger, got \(item.trigger)")
            }
            XCTAssertTrue(repeats, "A weekly repeat holds one slot forever; enumerating dates would exhaust the 64-request budget")
            XCTAssertEqual(components.weekday, weekday)
            XCTAssertEqual(components.hour, 20)
            XCTAssertEqual(components.minute, 30)
        }
    }

    func testWorstCasePlanStaysFarUnderThePendingRequestLimit() {
        var preferences = enabledPreferences()
        preferences.dailyEnabled = true
        preferences.dailyWeekdays = [1, 2, 3, 4, 5, 6, 7]
        preferences.sessionWindowEnabled = true
        preferences.inactivityEnabled = true

        let planned = plan(
            preferences,
            session: activeSession(remaining: 3600),
            lastSessionEndedAt: now.addingTimeInterval(-86_400)
        )

        // 7 daily + warn + end. The inactivity nudge is suppressed by the
        // active session, so 9 is the true ceiling — well under iOS's 64.
        XCTAssertEqual(planned.count, 9)
        XCTAssertLessThanOrEqual(planned.count, 10)
    }

    // MARK: - Session window

    func testActiveSessionSchedulesBothWarningAndEnd() {
        var preferences = enabledPreferences()
        preferences.sessionWarningLeadMinutes = 15

        let session = activeSession(remaining: 2400, kickCount: 7)
        let planned = plan(preferences, session: session)

        XCTAssertEqual(planned.count, 2)
        XCTAssertEqual(planned[0].id, "lt.session.warn.\(session.id.uuidString)")
        XCTAssertEqual(planned[0].trigger, .interval(1500))
        XCTAssertEqual(planned[1].id, "lt.session.end.\(session.id.uuidString)")
        XCTAssertEqual(planned[1].trigger, .interval(2400))
        XCTAssertEqual(planned[1].level, .timeSensitive)
        XCTAssertTrue(planned[1].body.contains("You counted 7 taps"))
    }

    func testWarningIsSuppressedRatherThanScheduledInThePast() {
        var preferences = enabledPreferences()
        preferences.sessionWarningLeadMinutes = 15

        let planned = plan(preferences, session: activeSession(remaining: 600))

        XCTAssertEqual(planned.count, 1)
        XCTAssertTrue(planned[0].id.contains("session.end"))
    }

    func testNothingIsScheduledInsideTheMinimumTriggerInterval() {
        let planned = plan(enabledPreferences(), session: activeSession(remaining: 30))

        XCTAssertTrue(planned.isEmpty, "iOS rejects sub-60s interval triggers; the user sees this in-app anyway")
    }

    func testPausedSessionSchedulesNothing() {
        let session = SessionSnapshot(
            id: UUID(),
            status: .paused,
            startedAt: now.addingTimeInterval(-1800),
            pausedAt: now.addingTimeInterval(-60),
            timeLimitSec: 7200,
            kickCount: 3,
            targetCount: 10
        )

        XCTAssertTrue(plan(enabledPreferences(), session: session).isEmpty)
    }

    func testTerminalSessionsScheduleNothing() {
        for status in [SessionStatus.complete, .timeout, .endedEarly] {
            let session = SessionSnapshot(
                id: UUID(),
                status: status,
                startedAt: now.addingTimeInterval(-1800),
                timeLimitSec: 7200,
                kickCount: 10,
                targetCount: 10
            )
            XCTAssertTrue(
                plan(enabledPreferences(), session: session).isEmpty,
                "Expected no requests for \(status.rawValue)"
            )
        }
    }

    func testSessionWindowCanBeTurnedOffIndependently() {
        var preferences = enabledPreferences()
        preferences.sessionWindowEnabled = false

        XCTAssertTrue(plan(preferences, session: activeSession(remaining: 3600)).isEmpty)
    }

    // MARK: - Inactivity

    func testInactivityNudgeIsSkippedWithoutAPriorSession() {
        var preferences = enabledPreferences()
        preferences.inactivityEnabled = true

        XCTAssertTrue(plan(preferences, lastSessionEndedAt: nil).isEmpty)
    }

    func testInactivityNudgeLandsAtTheEveningHourAfterTheThreshold() {
        var preferences = enabledPreferences()
        preferences.inactivityEnabled = true
        preferences.inactivityThresholdDays = 3

        let lastEnded = calendar.date(from: DateComponents(year: 2026, month: 6, day: 9, hour: 10))!
        let planned = plan(preferences, lastSessionEndedAt: lastEnded)

        XCTAssertEqual(planned.count, 1)
        XCTAssertEqual(planned[0].id, "lt.inactivity")
        XCTAssertEqual(planned[0].level, .passive)
        guard case .calendar(let components, let repeats) = planned[0].trigger else {
            return XCTFail("Expected a calendar trigger")
        }
        XCTAssertFalse(repeats)
        XCTAssertEqual(components.year, 2026)
        XCTAssertEqual(components.month, 6)
        XCTAssertEqual(components.day, 12)
        XCTAssertEqual(components.hour, 19)
    }

    func testInactivityNudgeIsPushedOutOfOvernightQuietHours() {
        var preferences = enabledPreferences()
        preferences.inactivityEnabled = true
        preferences.inactivityThresholdDays = 3
        preferences.dailyEnabled = true
        preferences.dailyHour = 23
        preferences.dailyWeekdays = []

        let lastEnded = calendar.date(from: DateComponents(year: 2026, month: 6, day: 9, hour: 10))!
        let planned = plan(preferences, lastSessionEndedAt: lastEnded)
            .filter { $0.id == "lt.inactivity" }

        XCTAssertEqual(planned.count, 1)
        guard case .calendar(let components, _) = planned[0].trigger else {
            return XCTFail("Expected a calendar trigger")
        }
        XCTAssertEqual(components.hour, NotificationPlanner.quietHoursFallbackHour)
        XCTAssertEqual(components.day, 13, "23:00 should roll to the following morning, not the same one")
    }

    /// The anti-spam guarantee: once the nudge's moment has passed it is not
    /// rolled forward, so it fires at most once per quiet spell instead of
    /// turning into a daily accusation.
    func testInactivityNudgeIsNotRolledForwardOnceItsMomentHasPassed() {
        var preferences = enabledPreferences()
        preferences.inactivityEnabled = true
        preferences.inactivityThresholdDays = 3

        let lastEnded = now.addingTimeInterval(-10 * 86_400)

        XCTAssertTrue(plan(preferences, lastSessionEndedAt: lastEnded).isEmpty)
    }

    func testInactivityNudgeNeverArrivesDuringASession() {
        var preferences = enabledPreferences()
        preferences.inactivityEnabled = true
        preferences.sessionWindowEnabled = false

        let planned = plan(
            preferences,
            session: activeSession(remaining: 3600),
            lastSessionEndedAt: now.addingTimeInterval(-86_400)
        )

        XCTAssertTrue(planned.isEmpty)
    }

    func testInactivityNudgeIsOffByDefault() {
        XCTAssertFalse(NotificationPreferences.default.inactivityEnabled)
        XCTAssertFalse(NotificationPreferences.default.masterEnabled)
    }

    // MARK: - Idempotence

    /// `reconcile` removes and rewrites whatever the planner returns, so an
    /// unstable plan would rewrite the schedule on every app launch.
    func testPlanIsStableAcrossCalls() {
        var preferences = enabledPreferences()
        preferences.dailyEnabled = true
        preferences.inactivityEnabled = true

        let session = activeSession(remaining: 3600, kickCount: 4)
        let lastEnded = now.addingTimeInterval(-86_400)

        XCTAssertEqual(
            plan(preferences, session: session, lastSessionEndedAt: lastEnded),
            plan(preferences, session: session, lastSessionEndedAt: lastEnded)
        )
    }

    func testEveryIdentifierCarriesThePrefixReconcileFiltersOn() {
        var preferences = enabledPreferences()
        preferences.dailyEnabled = true

        let planned = plan(preferences, session: activeSession(remaining: 3600))

        XCTAssertFalse(planned.isEmpty)
        for item in planned {
            XCTAssertTrue(item.id.hasPrefix(NotificationPlanner.idPrefix))
        }
    }

    // MARK: - Copy

    func testTapCountStatesTheNumberAsAFactAndPluralisesIt() {
        XCTAssertEqual(NotificationPlanner.tapCount(0), "You counted 0 taps")
        XCTAssertEqual(NotificationPlanner.tapCount(1), "You counted 1 tap")
        XCTAssertEqual(NotificationPlanner.tapCount(7), "You counted 7 taps")
    }

    /// The copy rules are load-bearing in a pregnancy-anxiety context, so
    /// assert on them rather than trusting review to catch a regression.
    func testNoNotificationBodyImpliesAMedicalAssessmentOrCountsTheGap() {
        var preferences = enabledPreferences()
        preferences.dailyEnabled = true
        preferences.inactivityEnabled = true

        let planned = plan(
            preferences,
            session: activeSession(remaining: 3600, kickCount: 2),
            lastSessionEndedAt: nil
        ) + plan(preferences, lastSessionEndedAt: now.addingTimeInterval(-86_400))

        let forbidden = ["should", "normal", "concerning", "doctor", "only counted", "days since"]
        for item in planned {
            let text = "\(item.title) \(item.subtitle ?? "") \(item.body)".lowercased()
            for phrase in forbidden {
                XCTAssertFalse(text.contains(phrase), "\"\(phrase)\" must never appear in \(item.id)")
            }
        }
    }
}
