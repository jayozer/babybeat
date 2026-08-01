import SwiftUI

struct RootView: View {
    @EnvironmentObject private var preferences: PreferencesStore

    var body: some View {
        Group {
            if preferences.preferences.hasCompletedOnboarding {
                TabView {
                    NavigationStack {
                        SessionView()
                    }
                    .tabItem { Label("Counter", systemImage: "heart.fill") }

                    NavigationStack {
                        HistoryView()
                    }
                    .tabItem { Label("History", systemImage: "calendar") }

                    NavigationStack {
                        SettingsView()
                    }
                    .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                }
                .tint(Theme.primary)
            } else {
                OnboardingView {
                    preferences.update { $0.hasCompletedOnboarding = true }
                }
            }
        }
    }
}
