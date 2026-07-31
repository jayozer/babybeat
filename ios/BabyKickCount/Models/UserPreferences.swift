import Foundation

struct UserPreferences: Codable, Equatable {
    var defaultTargetCount: Int = 10
    var defaultTimeLimitSec: Int = 7200
    var soundOption: SoundOption = .softClick
    var vibrationEnabled: Bool = true
    var keepScreenAwake: Bool = true
    var hasCompletedOnboarding: Bool = false

    static let `default` = UserPreferences()

    enum CodingKeys: String, CodingKey {
        case defaultTargetCount
        case defaultTimeLimitSec
        case soundOption
        case vibrationEnabled
        case keepScreenAwake
        case hasCompletedOnboarding
    }
}

/// Swift's *synthesized* `Decodable` ignores property default values: a key
/// missing from the stored blob throws `.keyNotFound`, `PreferencesStore`
/// swallows that with `try?`, and every setting silently resets to
/// `.default` — including `hasCompletedOnboarding`, which would re-run
/// onboarding on upgrade.
///
/// So each key is decoded with `decodeIfPresent` and falls back to its
/// default. Adding a field is then forward-compatible: blobs written by
/// older builds keep decoding. Declaring this in an extension rather than
/// in the type body preserves the memberwise initialiser that `.default`
/// relies on.
extension UserPreferences {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let fallback = UserPreferences.default

        defaultTargetCount = try container.decodeIfPresent(Int.self, forKey: .defaultTargetCount)
            ?? fallback.defaultTargetCount
        defaultTimeLimitSec = try container.decodeIfPresent(Int.self, forKey: .defaultTimeLimitSec)
            ?? fallback.defaultTimeLimitSec
        soundOption = try container.decodeIfPresent(SoundOption.self, forKey: .soundOption)
            ?? fallback.soundOption
        vibrationEnabled = try container.decodeIfPresent(Bool.self, forKey: .vibrationEnabled)
            ?? fallback.vibrationEnabled
        keepScreenAwake = try container.decodeIfPresent(Bool.self, forKey: .keepScreenAwake)
            ?? fallback.keepScreenAwake
        hasCompletedOnboarding = try container.decodeIfPresent(Bool.self, forKey: .hasCompletedOnboarding)
            ?? fallback.hasCompletedOnboarding
    }
}
