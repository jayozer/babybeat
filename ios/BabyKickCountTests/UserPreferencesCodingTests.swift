import XCTest
@testable import BabyKickCount

/// Guards the upgrade path. `PreferencesStore` decodes with `try?`, so any
/// decoding failure is indistinguishable from "no preferences yet" and
/// silently resets the user's settings. These tests fail loudly instead.
final class UserPreferencesCodingTests: XCTestCase {
    private func decode(_ json: String) throws -> UserPreferences {
        try JSONDecoder().decode(UserPreferences.self, from: Data(json.utf8))
    }

    /// The exact shape written by the shipped 1.0 build. Every value here is
    /// deliberately different from the default so a silent reset is visible.
    func testDecodesShippedV1BlobWithoutLosingAnySetting() throws {
        let decoded = try decode(
            """
            {
              "defaultTargetCount": 12,
              "defaultTimeLimitSec": 3600,
              "soundOption": "heartbeat",
              "vibrationEnabled": false,
              "keepScreenAwake": false,
              "hasCompletedOnboarding": true
            }
            """
        )

        XCTAssertEqual(decoded.defaultTargetCount, 12)
        XCTAssertEqual(decoded.defaultTimeLimitSec, 3600)
        XCTAssertEqual(decoded.soundOption, .heartbeat)
        XCTAssertFalse(decoded.vibrationEnabled)
        XCTAssertFalse(decoded.keepScreenAwake)
        XCTAssertTrue(decoded.hasCompletedOnboarding)
    }

    /// The whole point of the custom decoder: a blob missing keys that a
    /// later build added must keep the keys it does have.
    func testMissingKeysFallBackToDefaultsWithoutDiscardingPresentOnes() throws {
        let decoded = try decode(
            """
            { "soundOption": "bubble", "hasCompletedOnboarding": true }
            """
        )

        XCTAssertEqual(decoded.soundOption, .bubble)
        XCTAssertTrue(decoded.hasCompletedOnboarding)
        XCTAssertEqual(decoded.defaultTargetCount, UserPreferences.default.defaultTargetCount)
        XCTAssertEqual(decoded.defaultTimeLimitSec, UserPreferences.default.defaultTimeLimitSec)
        XCTAssertEqual(decoded.vibrationEnabled, UserPreferences.default.vibrationEnabled)
        XCTAssertEqual(decoded.keepScreenAwake, UserPreferences.default.keepScreenAwake)
    }

    func testEmptyObjectDecodesToDefaults() throws {
        XCTAssertEqual(try decode("{}"), .default)
    }

    func testRoundTripPreservesEveryField() throws {
        var original = UserPreferences.default
        original.defaultTargetCount = 8
        original.defaultTimeLimitSec = 5400
        original.soundOption = .pop
        original.vibrationEnabled = false
        original.keepScreenAwake = false
        original.hasCompletedOnboarding = true

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(UserPreferences.self, from: data)

        XCTAssertEqual(decoded, original)
    }

    /// A genuinely corrupt value should still throw rather than be papered
    /// over — `PreferencesStore` will fall back to defaults, which is the
    /// right behaviour for unreadable data.
    func testUnknownSoundOptionThrows() {
        XCTAssertThrowsError(try decode(#"{"soundOption": "kazoo"}"#))
    }
}
