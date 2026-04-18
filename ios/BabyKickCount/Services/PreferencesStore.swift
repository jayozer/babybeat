import Foundation
import SwiftUI

/// Preferences are small and flat so we persist them as JSON in UserDefaults.
@MainActor
final class PreferencesStore: ObservableObject {
    private static let key = "BabyKickCount.preferences"

    @Published var preferences: UserPreferences {
        didSet { persist() }
    }

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.key),
           let decoded = try? JSONDecoder().decode(UserPreferences.self, from: data) {
            self.preferences = decoded
        } else {
            self.preferences = .default
        }
    }

    func update(_ mutate: (inout UserPreferences) -> Void) {
        var copy = preferences
        mutate(&copy)
        preferences = copy
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(preferences) else { return }
        UserDefaults.standard.set(data, forKey: Self.key)
    }
}
