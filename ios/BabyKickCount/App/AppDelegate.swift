import UIKit
import UserNotifications

/// The app otherwise has no delegate. This exists purely so notification
/// responses have somewhere to land.
///
/// It is wired with `@UIApplicationDelegateAdaptor` rather than by assigning
/// `UNUserNotificationCenter.delegate` from `App.init()`, because the delegate
/// has to be in place before `didFinishLaunchingWithOptions` returns to
/// receive a response that cold-launched the app. Setting it any later loses
/// that first tap.
@MainActor
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        NotificationService.shared.registerCategories()
        return true
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        // Session alerts are pure noise while the app is already open — the
        // timer and the summary sheet have said it better, and a banner would
        // land right over the tap pad.
        if notification.request.content.categoryIdentifier == NotificationCategory.session {
            return []
        }
        return [.banner, .sound, .list]
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        guard response.actionIdentifier == NotificationAction.snooze else { return }
        // Runs in the background; the app is never brought forward for this.
        await NotificationService.shared.scheduleSnooze()
    }
}
