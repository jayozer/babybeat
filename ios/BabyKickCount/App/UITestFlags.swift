import Foundation

/// Launch-argument switches used only by the UI test bundle.
///
/// The Reminders screen hides most of its controls behind an OS permission
/// prompt, and driving a springboard alert from XCUITest is the flakiest thing
/// in the framework. Rather than automate the prompt, the tests ask the app to
/// render every section so the controls can be measured — otherwise the 44pt
/// hit-target assertions would silently cover nothing.
///
/// These read launch arguments, which are never passed to a shipped build, so
/// they are inert in release without needing a compilation condition.
enum UITestFlags {
    static let showsAllReminderSections =
        ProcessInfo.processInfo.arguments.contains("-ltShowAllReminderSections")
}
