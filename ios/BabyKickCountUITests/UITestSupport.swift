import XCTest

extension XCUIElement {
    /// True once the element is present *and* actually tappable.
    ///
    /// `waitForExistence` alone is not enough: an element can be in the
    /// accessibility tree while it is still sliding into place, and a tap sent
    /// during that window is silently dropped.
    func waitUntilVisible(timeout: TimeInterval = 10) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if exists && isHittable { return true }
            usleep(200_000)
        }
        return false
    }
}

extension XCUIApplication {

    /// Steps through onboarding if it is showing, leaving the app on Counter.
    ///
    /// Onboarding appears only on a fresh install — exactly the state a CI
    /// runner or a freshly erased simulator starts in. Any test that targets
    /// the main screens has to clear it first, or it asserts against the
    /// onboarding screen and fails for the wrong reason.
    ///
    /// Returns false only if onboarding was showing and could not be cleared.
    @discardableResult
    func completeOnboardingIfPresent() -> Bool {
        let welcome = staticTexts["Welcome to Littletaps"]
        let pad = buttons["Tap to record a kick"]

        // Wait for whichever screen the app lands on rather than guessing a
        // fixed delay: onboarding on a clean install, Counter otherwise.
        let deadline = Date().addingTimeInterval(20)
        while Date() < deadline {
            if welcome.exists { break }
            if pad.exists { return true }
            usleep(200_000)
        }
        guard welcome.exists else { return pad.exists }

        for heading in ["One tap at a time", "2-hour session"] {
            guard advanceOnboarding(to: heading) else { return false }
        }

        let getStarted = buttons["Get Started"]
        guard getStarted.waitUntilVisible() else { return false }
        getStarted.tap()

        return pad.waitUntilVisible(timeout: 15)
    }

    /// Advances one onboarding page and confirms it landed.
    ///
    /// The button relabels itself from "Next" to "Get Started" on the last
    /// page, so the button cannot tell you which page you are on — the page
    /// heading can. A tap issued during the page transition is swallowed, so
    /// retry until the destination heading appears.
    func advanceOnboarding(to heading: String) -> Bool {
        let destination = staticTexts[heading]
        let next = buttons["Next"]

        for _ in 0..<3 {
            if destination.waitUntilVisible(timeout: 1) { return true }
            guard next.waitUntilVisible() else { return false }
            next.tap()
            if destination.waitUntilVisible(timeout: 6) { return true }
        }
        return false
    }
}
