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

extension PreferencesStore {
    /// Hand-rolling a `Binding` per setting stops scaling once a screen has
    /// ten of them, so route them through a key path instead.
    func binding<V>(_ keyPath: WritableKeyPath<UserPreferences, V>) -> Binding<V> {
        Binding(
            get: { self.preferences[keyPath: keyPath] },
            set: { newValue in self.update { $0[keyPath: keyPath] = newValue } }
        )
    }

    /// Convenience for nested groups such as `notifications`.
    func binding<Group, V>(
        _ group: WritableKeyPath<UserPreferences, Group>,
        _ keyPath: WritableKeyPath<Group, V>
    ) -> Binding<V> {
        binding(group.appending(path: keyPath))
    }
}
