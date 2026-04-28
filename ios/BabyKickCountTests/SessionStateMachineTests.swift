import XCTest
@testable import BabyKickCount

final class SessionStateMachineTests: XCTestCase {
    func testStartTransitionsIdleSessionToActive() throws {
        let session = KickSession()

        try SessionStateMachine.start(session)

        XCTAssertEqual(session.status, .active)
        XCTAssertNotNil(session.startedAt)
    }

    func testPauseRejectsIdleSession() {
        let session = KickSession()

        XCTAssertThrowsError(try SessionStateMachine.pause(session)) { error in
            guard case SessionError.invalidTransition(let status, let action) = error else {
                return XCTFail("Expected invalid transition error, got \(error)")
            }
            XCTAssertEqual(status, .idle)
            XCTAssertEqual(action, "pause")
        }
    }

    func testElapsedTimeSubtractsCompletedAndCurrentPausedTime() {
        let now = Date(timeIntervalSince1970: 2_000)
        let session = KickSession(timeLimitSec: 120)
        session.status = .paused
        session.startedAt = now.addingTimeInterval(-100)
        session.pausedDurationSec = 20
        session.pausedAt = now.addingTimeInterval(-30)

        let elapsed = SessionStateMachine.elapsedSeconds(for: session, at: now)

        XCTAssertEqual(elapsed, 50, accuracy: 0.001)
    }

    func testTimeoutOnlyAppliesToActiveSessionsPastLimit() {
        let now = Date(timeIntervalSince1970: 2_000)
        let session = KickSession(timeLimitSec: 120)
        session.status = .active
        session.startedAt = now.addingTimeInterval(-121)

        XCTAssertTrue(SessionStateMachine.shouldTimeout(session, at: now))

        session.status = .paused

        XCTAssertFalse(SessionStateMachine.shouldTimeout(session, at: now))
    }

    func testAutoCompleteRequiresActiveSessionAtTarget() {
        let session = KickSession(targetCount: 10)
        session.status = .active
        session.kickCount = 10

        XCTAssertTrue(SessionStateMachine.shouldAutoComplete(session))

        session.status = .paused

        XCTAssertFalse(SessionStateMachine.shouldAutoComplete(session))
    }
}
