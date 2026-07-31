import AppIntents

/// Puts the intents in Spotlight, the Shortcuts app, and Siri with no setup by
/// the user, and makes them assignable to the Action button.
///
/// Two hard rules from the framework: at most ten `AppShortcut`s per app, and
/// every phrase must interpolate `\(.applicationName)` — the build fails
/// outright otherwise.
struct LittletapsShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogKickIntent(),
            phrases: [
                "Log a tap in \(.applicationName)",
                "Record a kick in \(.applicationName)",
                "Count a tap in \(.applicationName)"
            ],
            shortTitle: "Log a tap",
            systemImageName: "heart.fill"
        )

        AppShortcut(
            intent: StartSessionIntent(),
            phrases: [
                "Start counting in \(.applicationName)",
                "Start a \(.applicationName) session"
            ],
            shortTitle: "Start counting",
            systemImageName: "play.circle.fill"
        )

        AppShortcut(
            intent: KickCountQueryIntent(),
            phrases: [
                "How many taps in \(.applicationName)",
                "\(.applicationName) count so far"
            ],
            shortTitle: "Taps so far",
            systemImageName: "number.circle.fill"
        )

        AppShortcut(
            intent: EndSessionIntent(),
            phrases: [
                "End my \(.applicationName) session",
                "Finish counting in \(.applicationName)"
            ],
            shortTitle: "End the session",
            systemImageName: "stop.circle.fill"
        )
    }
}
