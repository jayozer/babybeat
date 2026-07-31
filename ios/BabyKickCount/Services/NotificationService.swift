import Foundation
import UserNotifications

/// Turns a `NotificationPlanner` plan into scheduled requests.
///
/// Follows the `FeedbackService` precedent — a capability wrapper whose
/// failures are non-fatal — but is an `ObservableObject` because the Reminders
/// screen has to react to the authorization status changing out from under it
/// (the user can revoke permission in Settings at any time).
@MainActor
final class NotificationService: ObservableObject {
    static let shared = NotificationService()

    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    /// Authorization states that actually permit delivery.
    var isAuthorized: Bool {
        switch authorizationStatus {
        case .authorized, .provisional, .ephemeral: return true
        default: return false
        }
    }

    // MARK: - Bootstrap

    /// Registers the action buttons. Categories are global to the app, so this
    /// runs once at launch regardless of whether anything is scheduled.
    func registerCategories() {
        let startCounting = UNNotificationAction(
            identifier: NotificationAction.startCounting,
            title: "Start counting",
            options: [.foreground]
        )
        let snooze = UNNotificationAction(
            identifier: NotificationAction.snooze,
            title: "Remind me in an hour",
            options: []
        )
        let open = UNNotificationAction(
            identifier: NotificationAction.open,
            title: "Open Littletaps",
            options: [.foreground]
        )

        center.setNotificationCategories([
            UNNotificationCategory(
                identifier: NotificationCategory.daily,
                actions: [startCounting, snooze],
                intentIdentifiers: [],
                options: []
            ),
            UNNotificationCategory(
                identifier: NotificationCategory.session,
                actions: [open],
                intentIdentifiers: [],
                options: []
            ),
            // The inactivity nudge deliberately offers no actions — it is a
            // note, not a prompt.
            UNNotificationCategory(
                identifier: NotificationCategory.quiet,
                actions: [],
                intentIdentifiers: [],
                options: []
            )
        ])
    }

    /// Handles "Remind me in an hour" without opening the app.
    func scheduleSnooze() async {
        let content = UNMutableNotificationContent()
        content.title = "Still here"
        content.body = "Ready whenever you are."
        content.sound = .default
        content.categoryIdentifier = NotificationCategory.daily
        content.threadIdentifier = NotificationThread.reminders
        content.interruptionLevel = .active
        content.relevanceScore = 0.5
        attachArt(.heart, to: content)

        let request = UNNotificationRequest(
            identifier: "\(NotificationPlanner.idPrefix)daily.snooze",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 3600, repeats: false)
        )
        try? await center.add(request)
    }

    // MARK: - Authorization

    func refreshAuthorizationStatus() async {
        authorizationStatus = await center.notificationSettings().authorizationStatus
    }

    /// Returns whether notifications may now be delivered. A `false` here is
    /// terminal for this install — iOS only ever shows the system prompt once,
    /// so the caller must fall back to deep-linking into Settings.
    @discardableResult
    func requestAuthorization() async -> Bool {
        // Deliberately no `.criticalAlert`: it needs Apple's approval and
        // would be indefensible for an app that is explicitly not a medical
        // device.
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        await refreshAuthorizationStatus()
        return granted
    }

    // MARK: - Scheduling

    /// The only mutation entry point, and idempotent by construction: it
    /// computes the desired set, removes everything of ours that is no longer
    /// wanted, then rewrites what is. Safe to call as often as you like —
    /// every caller fires it into a `Task` and never waits.
    func reconcile(
        preferences: NotificationPreferences,
        session: SessionSnapshot?,
        lastSessionEndedAt: Date?,
        now: Date = .now
    ) async {
        // Always re-read first. At launch the cached status is still
        // `.notDetermined`, and reconciling against that would plan nothing
        // and so delete every request we had legitimately scheduled. It also
        // picks up permission the user revoked in Settings while we were gone.
        await refreshAuthorizationStatus()

        let planned = NotificationPlanner.plan(
            preferences: preferences,
            authorized: isAuthorized,
            session: session,
            lastSessionEndedAt: lastSessionEndedAt,
            at: now
        )

        let ours = await center.pendingNotificationRequests()
            .map(\.identifier)
            .filter { $0.hasPrefix(NotificationPlanner.idPrefix) }

        let plannedIDs = planned.map(\.id)
        let stale = Set(ours).subtracting(plannedIDs)
        if !stale.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: Array(stale))
        }

        guard !planned.isEmpty else { return }

        // Remove-then-add rather than "skip if already pending": identifiers
        // are stable across a content change (the user editing the reminder
        // time keeps `lt.daily.2`), and an interval trigger's countdown has to
        // restart from now anyway.
        center.removePendingNotificationRequests(withIdentifiers: plannedIDs)
        for item in planned {
            try? await center.add(request(for: item))
        }
    }

    func cancelAll() {
        Task {
            let ours = await center.pendingNotificationRequests()
                .map(\.identifier)
                .filter { $0.hasPrefix(NotificationPlanner.idPrefix) }
            center.removePendingNotificationRequests(withIdentifiers: ours)
        }
    }

    /// Fires shortly after being called so the user can see exactly what a
    /// reminder looks like before committing to one. By far the fastest way to
    /// verify appearance by hand, too.
    func sendTestReminder() async {
        let content = UNMutableNotificationContent()
        content.title = "Here's how it looks"
        content.body = "Find a comfy spot and tap along with your little one."
        content.sound = .default
        content.threadIdentifier = NotificationThread.reminders
        attachArt(.heart, to: content)

        let request = UNNotificationRequest(
            identifier: "\(NotificationPlanner.idPrefix)test",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        )
        try? await center.add(request)
    }

    // MARK: - Request building

    private func request(for planned: PlannedNotification) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = planned.title
        if let subtitle = planned.subtitle {
            content.subtitle = subtitle
        }
        content.body = planned.body
        content.sound = .default
        content.categoryIdentifier = planned.categoryID
        content.threadIdentifier = planned.threadID
        content.relevanceScore = planned.relevance
        content.interruptionLevel = interruptionLevel(for: planned.level)
        if let artKind = planned.artKind {
            attachArt(artKind, to: content)
        }

        return UNNotificationRequest(
            identifier: planned.id,
            content: content,
            trigger: trigger(for: planned.trigger)
        )
    }

    /// The thumbnail on the banner. Silently skipped on failure — a
    /// notification without artwork is still a perfectly good notification.
    private func attachArt(_ kind: NotificationArtKind, to content: UNMutableNotificationContent) {
        guard let url = NotificationArtRenderer.attachmentURL(for: kind),
              let attachment = try? UNNotificationAttachment(
                  identifier: kind.rawValue,
                  url: url,
                  options: nil
              ) else { return }
        content.attachments = [attachment]
    }

    private func interruptionLevel(for level: PlannedLevel) -> UNNotificationInterruptionLevel {
        switch level {
        case .passive: return .passive
        case .active: return .active
        case .timeSensitive: return .timeSensitive
        }
    }

    private func trigger(for planned: PlannedTrigger) -> UNNotificationTrigger {
        switch planned {
        case .calendar(let components, let repeats):
            return UNCalendarNotificationTrigger(dateMatching: components, repeats: repeats)
        case .interval(let seconds):
            return UNTimeIntervalNotificationTrigger(
                timeInterval: max(NotificationPlanner.minimumInterval, seconds),
                repeats: false
            )
        }
    }
}
