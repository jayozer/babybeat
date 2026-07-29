import XCTest

/// Captures the App Store product-page screenshots.
///
/// This is tooling rather than a regression test. It walks the app through each
/// screen and writes full-resolution PNGs into the test runner's Documents
/// directory, where `Scripts/capture-screenshots.sh` collects them.
///
/// It is skipped unless that script asks for it, because it needs a freshly
/// installed app to reach onboarding and it leaves a completed session behind.
/// Screenshots have to match the submitted binary, so re-run the script after
/// any visual change rather than editing the PNGs.
final class ScreenshotCaptureTests: XCTestCase {

    private var app: XCUIApplication!
    private var outputDirectory: URL!

    override func setUpWithError() throws {
        try XCTSkipUnless(
            ProcessInfo.processInfo.environment["CAPTURE_SCREENSHOTS"] == "1",
            "run ios/Scripts/capture-screenshots.sh to regenerate the App Store screenshots"
        )
        continueAfterFailure = false
        outputDirectory = try makeOutputDirectory()
        app = XCUIApplication()
    }

    func testCaptureAppStoreScreenshots() throws {
        app.launch()

        // 1-3: onboarding, which only appears on a fresh install. That is why
        // the script erases the simulator before each run.
        XCTAssertTrue(
            waitUntilVisible(app.staticTexts["Welcome to Littletaps"], timeout: 25),
            "onboarding did not appear — the app was probably already installed"
        )
        settle()
        capture("01_onboarding_welcome")

        advanceOnboarding(to: "One tap at a time")
        capture("02_onboarding_tap")

        advanceOnboarding(to: "2-hour session")
        capture("03_onboarding_timer")

        let getStarted = app.buttons["Get Started"]
        XCTAssertTrue(waitUntilVisible(getStarted), "onboarding never reached 'Get Started'")
        getStarted.tap()

        // 4: the counter before anything is recorded.
        let pad = app.buttons["Tap to record a kick"]
        XCTAssertTrue(waitUntilVisible(pad, timeout: 15), "tap pad not found")
        settle()
        capture("04_counter_ready")

        // 5: mid-session. Three of ten, matching the previous set.
        tapPad(pad, times: 3)
        settle()
        capture("05_counter_active")

        // 6: the summary sheet, which presents itself on the tenth tap.
        tapPad(pad, times: 7)
        let close = app.buttons["Close"]
        XCTAssertTrue(waitUntilVisible(close, timeout: 15), "summary sheet did not present")
        settle()
        capture("06_session_summary")

        close.tap()
        settle()

        // 7: history, now holding the session just completed.
        goToTab("History")
        settle()
        capture("07_history")

        // 8: settings.
        goToTab("Settings")
        settle()
        capture("08_settings")

        // 9: the information screen, which carries the medical disclaimer.
        let info = app.buttons["Information & Help"]
        var swipes = 0
        while !info.exists && swipes < 6 {
            app.swipeUp()
            settle()
            swipes += 1
        }
        XCTAssertTrue(
            info.waitForExistence(timeout: 5),
            "could not reach 'Information & Help' after \(swipes) swipes"
        )
        info.tap()
        settle()
        capture("09_info")
    }

    // MARK: - Helpers

    /// Page transitions, the sheet presentation and the tab switch are all
    /// animated. The previous screenshot set was captured mid-animation — a
    /// ghosted tab bar in the counter shot, a half-scrolled row in settings —
    /// so wait for things to come to rest before capturing.
    private func settle() {
        usleep(1_500_000)
    }

    /// `waitForExistence` is not enough here: an element can be in the tree
    /// while it is still sliding into place, and a tap sent then is dropped.
    private func waitUntilVisible(_ element: XCUIElement, timeout: TimeInterval = 10) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if element.exists && element.isHittable { return true }
            usleep(200_000)
        }
        return false
    }

    /// Advances one onboarding page and confirms it landed.
    ///
    /// The button relabels itself from "Next" to "Get Started" on the last
    /// page, so the button alone cannot tell you which page you are on — the
    /// page heading can. A tap issued during the page transition is silently
    /// swallowed, which is exactly how a previous run ended up two pages in
    /// after three taps, so retry until the destination heading appears.
    private func advanceOnboarding(to heading: String,
                                   file: StaticString = #filePath,
                                   line: UInt = #line) {
        let destination = app.staticTexts[heading]
        let next = app.buttons["Next"]

        for attempt in 1...3 {
            if waitUntilVisible(destination, timeout: 1) { break }

            XCTAssertTrue(waitUntilVisible(next),
                          "onboarding 'Next' button never became tappable",
                          file: file, line: line)
            next.tap()

            if waitUntilVisible(destination, timeout: 6) { break }
            XCTAssertLessThan(attempt, 3,
                              "onboarding never advanced to '\(heading)'",
                              file: file, line: line)
        }
        settle()
    }

    private func tapPad(_ pad: XCUIElement, times: Int) {
        for _ in 0..<times {
            guard pad.isEnabled, pad.isHittable else { return }
            pad.tap()
            usleep(400_000)
        }
    }

    private func goToTab(_ name: String,
                         file: StaticString = #filePath,
                         line: UInt = #line) {
        let tab = app.buttons[name]
        XCTAssertTrue(waitUntilVisible(tab, timeout: 15),
                      "could not reach the \(name) tab", file: file, line: line)
        tab.tap()
    }

    private func capture(_ name: String,
                         file: StaticString = #filePath,
                         line: UInt = #line) {
        let screenshot = XCUIScreen.main.screenshot()

        // Attached as well as written out, so a failed run still leaves the
        // partial set visible in the .xcresult.
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)

        do {
            try screenshot.pngRepresentation.write(
                to: outputDirectory.appendingPathComponent("\(name).png")
            )
        } catch {
            XCTFail("could not write \(name).png: \(error)", file: file, line: line)
        }
    }

    private func makeOutputDirectory() throws -> URL {
        let documents = try FileManager.default.url(
            for: .documentDirectory, in: .userDomainMask,
            appropriateFor: nil, create: true
        )
        let directory = documents.appendingPathComponent("AppStoreScreenshots", isDirectory: true)
        // Start clean so a partial run cannot leave stale files behind for the
        // script to collect and mistake for the current set.
        try? FileManager.default.removeItem(at: directory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
}
