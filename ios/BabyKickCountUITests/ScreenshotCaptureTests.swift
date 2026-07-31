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
            app.staticTexts["Welcome to Littletaps"].waitUntilVisible(timeout: 25),
            "onboarding did not appear — the app was probably already installed"
        )
        settle()
        capture("01_onboarding_welcome")

        advanceOnboarding(to: "One tap at a time")
        capture("02_onboarding_tap")

        advanceOnboarding(to: "2-hour session")
        capture("03_onboarding_timer")

        // The disclaimer page is stepped through but not captured. It is
        // already represented on the product page by 09_info, and a legal
        // notice makes a poor marketing screenshot.
        advanceOnboarding(to: "Not a medical device")

        let getStarted = app.buttons["Get Started"]
        XCTAssertTrue(getStarted.waitUntilVisible(), "onboarding never reached 'Get Started'")
        getStarted.tap()

        // 4: the counter before anything is recorded.
        let pad = app.buttons["Tap to record a kick"]
        XCTAssertTrue(pad.waitUntilVisible(timeout: 15), "tap pad not found")
        settle()
        capture("04_counter_ready")

        // 5: mid-session. Three of ten, matching the previous set.
        tapPad(pad, times: 3)
        settle()
        capture("05_counter_active")

        // 6: the summary sheet, which presents itself on the tenth tap.
        tapPad(pad, times: 7)
        let close = app.buttons["Close"]
        XCTAssertTrue(close.waitUntilVisible(timeout: 15), "summary sheet did not present")
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

    /// Advances one onboarding page, then waits for the animation to finish so
    /// the next capture lands on a settled screen.
    private func advanceOnboarding(to heading: String,
                                   file: StaticString = #filePath,
                                   line: UInt = #line) {
        XCTAssertTrue(app.advanceOnboarding(to: heading),
                      "onboarding never advanced to '\(heading)'",
                      file: file, line: line)
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
        XCTAssertTrue(tab.waitUntilVisible(timeout: 15),
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
