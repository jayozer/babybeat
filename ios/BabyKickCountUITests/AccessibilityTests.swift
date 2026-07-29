import XCTest

/// Accessibility regression tests.
///
/// These cover what Accessibility Inspector's audit tab checks — unlabelled
/// controls and hit targets under 44pt — plus a layout check the audit cannot
/// do: that the calendar stays legible at accessibility text sizes. That last
/// one guards a real bug where two-digit day numbers wrapped into "1" over "0".
final class AccessibilityTests: XCTestCase {

    private var app: XCUIApplication!

    /// Apple's minimum comfortable hit target. Sub-pixel layout means an
    /// intended 44pt can measure 43.9996, so compare with a small tolerance.
    private let minimumTarget: CGFloat = 44
    private let tolerance: CGFloat = 0.05

    override func setUpWithError() throws {
        continueAfterFailure = true
        app = XCUIApplication()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Helpers

    /// Navigation bars and tab bars are system chrome. Their buttons use
    /// Apple's own 36pt bar-item height and the bar absorbs the extra touch
    /// slop, so holding them to 44pt would only produce false failures.
    private var systemChrome: [CGRect] {
        let bars = app.navigationBars.allElementsBoundByIndex
            + app.tabBars.allElementsBoundByIndex
        return bars.filter(\.exists).map(\.frame)
    }

    /// Every control the user can actually tap on the current screen.
    ///
    /// Only buttons and links are checked. A SwiftUI `Toggle` in a `Form`
    /// exposes the switch itself as a 63x28 child, but the tappable element is
    /// the full-width row that wraps it — measuring the child would report a
    /// failure that does not exist for the user.
    private func tappableControls() -> [XCUIElement] {
        let chrome = systemChrome
        return app.descendants(matching: .any)
            .allElementsBoundByAccessibilityElement
            .filter { element in
                guard element.exists, element.isHittable else { return false }
                guard element.elementType == .button || element.elementType == .link else {
                    return false
                }
                return !chrome.contains { $0.contains(element.frame) }
            }
    }

    private func assertHitTargets(on screen: String,
                                  file: StaticString = #filePath,
                                  line: UInt = #line) {
        for control in tappableControls() {
            let frame = control.frame
            let label = control.label.isEmpty ? "<no label>" : control.label
            XCTAssertGreaterThanOrEqual(
                frame.width, minimumTarget - tolerance,
                "\(screen): '\(label)' is \(frame.width)pt wide, under the 44pt minimum",
                file: file, line: line
            )
            XCTAssertGreaterThanOrEqual(
                frame.height, minimumTarget - tolerance,
                "\(screen): '\(label)' is \(frame.height)pt tall, under the 44pt minimum",
                file: file, line: line
            )
        }
    }

    private func assertAllControlsLabelled(on screen: String,
                                           file: StaticString = #filePath,
                                           line: UInt = #line) {
        for control in tappableControls() {
            XCTAssertFalse(
                control.label.trimmingCharacters(in: .whitespaces).isEmpty,
                "\(screen): a \(control.elementType.rawValue) at \(control.frame) has no accessibility label",
                file: file, line: line
            )
        }
    }

    private func goToTab(_ name: String,
                         file: StaticString = #filePath,
                         line: UInt = #line) {
        let tab = app.buttons[name]
        XCTAssertTrue(tab.waitForExistence(timeout: 10),
                      "could not find the \(name) tab", file: file, line: line)
        tab.tap()
    }

    /// Taps the pad until the session completes. The pad disables the moment it
    /// does, which is the signal to stop.
    private func completeASession(file: StaticString = #filePath,
                                  line: UInt = #line) {
        let pad = app.buttons["Tap to record a kick"]
        XCTAssertTrue(pad.waitForExistence(timeout: 10),
                      "tap pad not found", file: file, line: line)
        for _ in 0..<12 {
            guard pad.isEnabled, pad.isHittable else { return }
            pad.tap()
            usleep(250_000)
        }
    }

    /// Completing a session presents the summary sheet over the tab bar, so it
    /// has to come down before anything else is reachable.
    private func dismissSummarySheet() {
        let close = app.buttons["Close"]
        if close.waitForExistence(timeout: 5) {
            close.tap()
            usleep(600_000)
        }
    }

    // MARK: - Hit targets and labels, across every screen

    func testEveryScreenMeetsHitTargetAndLabelMinimums() {
        app.launch()

        assertHitTargets(on: "Counter")
        assertAllControlsLabelled(on: "Counter")

        goToTab("History")
        assertHitTargets(on: "History")
        assertAllControlsLabelled(on: "History")

        goToTab("Settings")
        assertHitTargets(on: "Settings")
        assertAllControlsLabelled(on: "Settings")

        // The About section sits below the fold.
        let info = app.buttons["Information & Help"]
        var swipes = 0
        while !info.exists && swipes < 6 {
            app.swipeUp()
            usleep(400_000)
            swipes += 1
        }
        XCTAssertTrue(info.waitForExistence(timeout: 5),
                      "could not reach 'Information & Help' after \(swipes) swipes")
        info.tap()
        assertHitTargets(on: "Info")
        assertAllControlsLabelled(on: "Info")
    }

    // MARK: - The specific labels VoiceOver reads out

    func testCalendarDaysAreButtonsWithDescriptiveLabels() {
        app.launch()
        goToTab("History")

        // A day should read as a full date plus its session count — not a bare
        // "27" with no traits.
        let dayCells = app.buttons.matching(
            NSPredicate(format: "label MATCHES %@", ".*, .* \\d+, \\d{4}.*")
        )
        XCTAssertGreaterThan(dayCells.count, 27,
                             "expected a labelled button for each day of the month")

        let firstDay = dayCells.element(boundBy: 0)
        XCTAssertTrue(firstDay.label.contains("session"),
                      "day label '\(firstDay.label)' should state the session count")
    }

    func testHistoryRowMenuIsLabelled() {
        app.launch()
        completeASession()
        dismissSummarySheet()

        goToTab("History")
        let menu = app.buttons["Session options"].firstMatch
        XCTAssertTrue(menu.waitForExistence(timeout: 10),
                      "history row menu should be labelled 'Session options'")
    }

    func testSoundPreviewButtonsAreLabelled() {
        app.launch()
        goToTab("Settings")

        for sound in ["Soft Click", "Pop", "Heartbeat", "Bubble"] {
            let preview = app.buttons["Preview \(sound) sound"]
            XCTAssertTrue(preview.waitForExistence(timeout: 5),
                          "missing a labelled preview button for \(sound)")
        }
    }

    func testStarRatingButtonsAreLabelled() {
        app.launch()
        completeASession()

        // Completing a session presents the summary sheet.
        for value in 1...5 {
            let label = value == 1 ? "Rate 1 star" : "Rate \(value) stars"
            let star = app.buttons[label]
            XCTAssertTrue(star.waitForExistence(timeout: 10),
                          "missing a labelled star button: '\(label)'")
        }
    }

    // MARK: - Dynamic Type

    func testCalendarStaysLegibleAtLargestAccessibilityTextSize() {
        app.launchArguments += [
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryAccessibilityXXXL"
        ]
        app.launch()
        goToTab("History")

        let dayCells = app.buttons.matching(
            NSPredicate(format: "label MATCHES %@", ".*, .* \\d+, \\d{4}.*")
        ).allElementsBoundByIndex.filter(\.isHittable)

        XCTAssertGreaterThan(dayCells.count, 27,
                             "every day should still be reachable at AX5")

        // Every cell has identical structure, so their heights should match. If
        // a two-digit number wraps to a second line while "1" does not, the
        // tall cells give it away.
        let heights = dayCells.map(\.frame.height)
        guard let shortest = heights.min(), let tallest = heights.max(), shortest > 0 else {
            return XCTFail("could not measure calendar day cells")
        }
        XCTAssertLessThan(
            tallest / shortest, 1.3,
            "day cells vary from \(shortest)pt to \(tallest)pt at AX5, which means "
            + "some day numbers are wrapping onto a second line"
        )
    }
}
