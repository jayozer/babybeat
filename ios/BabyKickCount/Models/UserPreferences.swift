import Foundation

struct UserPreferences: Codable, Equatable {
    var defaultTargetCount: Int = 10
    var defaultTimeLimitSec: Int = 7200
    var soundOption: SoundOption = .softClick
    var vibrationEnabled: Bool = true
    var keepScreenAwake: Bool = true
    var hasCompletedOnboarding: Bool = false

    static let `default` = UserPreferences()
}
