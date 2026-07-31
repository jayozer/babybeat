import XCTest
@testable import BabyKickCount

/// The disclaimer is what keeps a fetal-movement app on the right side of the
/// "not a medical device" line, both for App Review and for the person using
/// it. These assert the load-bearing claims survive a copy edit — the two
/// screens previously carried separately worded versions, and only one of them
/// said the app does not replace professional care.
final class MedicalDisclaimerTests: XCTestCase {

    func testDisclaimerMakesEveryRequiredClaim() {
        let text = MedicalDisclaimer.body.lowercased()

        let required = [
            "not a medical device",
            "does not diagnose",
            "does not replace",
            "healthcare provider"
        ]

        for claim in required {
            XCTAssertTrue(
                text.contains(claim),
                "the medical disclaimer no longer says '\(claim)' — "
                + "it reads: \(MedicalDisclaimer.body)"
            )
        }
    }

    /// The body is a multi-line literal with escaped line continuations. A
    /// missing backslash would silently introduce newlines mid-sentence, which
    /// renders as broken text rather than failing to compile.
    func testDisclaimerIsASingleUnbrokenParagraph() {
        XCTAssertFalse(MedicalDisclaimer.body.contains("\n"),
                       "the disclaimer should be one paragraph with no hard line breaks")
        XCTAssertFalse(MedicalDisclaimer.body.contains("  "),
                       "the disclaimer contains a double space, so a line continuation is malformed")
    }
}
