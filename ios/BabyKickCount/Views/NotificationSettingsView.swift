import SwiftUI
import UIKit
import UserNotifications

/// Deliberately a hybrid register: a stock `Form` (so Dynamic Type, 44pt row
/// heights and VoiceOver semantics come free, and the accessibility tests stay
/// green) layered over the app's gradient, with the grouped sections reading
/// close to `softCard()`.
struct NotificationSettingsView: View {
    @EnvironmentObject private var preferences: PreferencesStore
    @EnvironmentObject private var notifications: NotificationService
    @Environment(\.scenePhase) private var scenePhase

    @State private var testSent = false

    private var prefs: NotificationPreferences { preferences.preferences.notifications }

    private var showsDetail: Bool { prefs.masterEnabled || UITestFlags.showsAllReminderSections }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            Form {
                heroSection
                mainSection
                if showsDetail {
                    dailySection
                    sessionSection
                    inactivitySection
                    testSection
                }
                disclaimerSection
            }
            .scrollContentBackground(.hidden)
            .tint(Theme.primary)
        }
        .navigationTitle("Reminders")
        .navigationBarTitleDisplayMode(.inline)
        .task { await notifications.refreshAuthorizationStatus() }
        .onChange(of: scenePhase) { _, phase in
            // Self-heals when the user comes back from the Settings app.
            guard phase == .active else { return }
            Task { await notifications.refreshAuthorizationStatus() }
        }
    }

    // MARK: - Sections

    private var heroSection: some View {
        Section {
            VStack(spacing: 12) {
                NotificationArtView(kind: .heart)
                    .frame(width: 120, height: 120)
                Text("a gentle nudge, on your schedule")
                    .font(.footnote)
                    .foregroundStyle(Theme.inkFaint)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("A gentle nudge, on your schedule")
        }
        .listRowBackground(Color.clear)
    }

    private var mainSection: some View {
        Section {
            Toggle("Reminders", isOn: masterBinding)
                .tint(Theme.primary)

            if notifications.authorizationStatus == .denied {
                Button {
                    openNotificationSettings()
                } label: {
                    Label("Turn on in Settings", systemImage: "arrow.up.forward.app")
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(Theme.primary)
            }
        } footer: {
            if notifications.authorizationStatus == .denied {
                Text("Notifications are turned off for Littletaps in iOS Settings.")
            } else {
                Text("Everything below is optional and off until you choose it.")
            }
        }
    }

    private var dailySection: some View {
        Section {
            Toggle("Daily reminder", isOn: binding(\.dailyEnabled))
                .tint(Theme.primary)

            if prefs.dailyEnabled || UITestFlags.showsAllReminderSections {
                DatePicker(
                    "Time",
                    selection: dailyTimeBinding,
                    displayedComponents: .hourAndMinute
                )
                WeekdayPicker(selection: binding(\.dailyWeekdays))
            }
        } header: {
            Text("Daily reminder")
        } footer: {
            Text("We'll nudge you once at this time on the days you pick.")
        }
    }

    private var sessionSection: some View {
        Section {
            Toggle("When my window is ending", isOn: binding(\.sessionWindowEnabled))
                .tint(Theme.primary)

            if prefs.sessionWindowEnabled || UITestFlags.showsAllReminderSections {
                Picker("Let me know", selection: binding(\.sessionWarningLeadMinutes)) {
                    ForEach(NotificationPreferences.warningLeadOptions, id: \.self) { minutes in
                        Text(minutes == 0 ? "Only at the end" : "\(minutes) min before")
                            .tag(minutes)
                    }
                }
            }
        } header: {
            Text("During a session")
        } footer: {
            Text("Littletaps can't count while it's closed — this tells you when your 2-hour window is up.")
        }
    }

    private var inactivitySection: some View {
        Section {
            Toggle("Gentle check-in", isOn: binding(\.inactivityEnabled))
                .tint(Theme.primary)

            if prefs.inactivityEnabled || UITestFlags.showsAllReminderSections {
                Picker("After", selection: binding(\.inactivityThresholdDays)) {
                    ForEach(NotificationPreferences.inactivityThresholdOptions, id: \.self) { days in
                        Text("\(days) days").tag(days)
                    }
                }
            }
        } header: {
            Text("If it's been a while")
        } footer: {
            Text("One quiet note if some time passes between sessions. It never arrives during a session, and never overnight.")
        }
    }

    private var testSection: some View {
        Section {
            Button {
                Task {
                    await notifications.sendTestReminder()
                    testSent = true
                }
            } label: {
                Text("Send a test reminder")
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(Theme.primary)
            .disabled(!notifications.isAuthorized)
        } footer: {
            Text(testSent
                 ? "On its way — leave Littletaps to see it arrive."
                 : "Arrives in a few seconds so you can see how it looks.")
        }
    }

    /// A real row rather than a bare `Section` footer, so it renders reliably
    /// and stays on screen without scrolling in the default (everything off)
    /// state — which is the state an App Reviewer opens this screen in.
    private var disclaimerSection: some View {
        Section {
            Text("Reminders are scheduled on your device. Littletaps never sends alerts about your baby's health — talk to your provider if anything changes.")
                .font(.footnote)
                .foregroundStyle(Theme.inkFaint)
                .listRowBackground(Color.clear)
        }
    }

    // MARK: - Bindings

    private func binding<V>(_ keyPath: WritableKeyPath<NotificationPreferences, V>) -> Binding<V> {
        preferences.binding(\.notifications, keyPath)
    }

    /// Turning the master switch on is itself the permission ask — the user
    /// navigated to a screen called Reminders and flipped it deliberately, so
    /// a separate "may we ask?" dialog in front of it is pure friction.
    private var masterBinding: Binding<Bool> {
        Binding(
            get: { prefs.masterEnabled },
            set: { newValue in
                guard newValue else {
                    preferences.update { $0.notifications.masterEnabled = false }
                    notifications.cancelAll()
                    return
                }
                Task {
                    let granted = await notifications.requestAuthorization()
                    // Never leave the switch showing "on" when iOS will
                    // deliver nothing; the Settings deep-link row appears
                    // instead.
                    preferences.update { $0.notifications.masterEnabled = granted }
                }
            }
        )
    }

    private var dailyTimeBinding: Binding<Date> {
        Binding(
            get: {
                var components = DateComponents()
                components.hour = prefs.dailyHour
                components.minute = prefs.dailyMinute
                return Calendar.current.date(from: components) ?? .now
            },
            set: { newValue in
                let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                preferences.update {
                    $0.notifications.dailyHour = components.hour ?? 20
                    $0.notifications.dailyMinute = components.minute ?? 0
                }
            }
        )
    }

    private func openNotificationSettings() {
        // Deep-links straight to Littletaps' notification pane rather than the
        // generic app settings page.
        guard let url = URL(string: UIApplication.openNotificationSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

/// Seven day toggles. Each has to clear 44×44 for `AccessibilityTests`, but a
/// `Form` row on the narrowest supported iPhone is only ~305pt wide and
/// 7 × 44 = 308 — so the row is allowed to scroll rather than squeeze the hit
/// targets below the minimum.
struct WeekdayPicker: View {
    @Binding var selection: Set<Int>

    private var symbols: [String] { Calendar.current.veryShortWeekdaySymbols }
    private var names: [String] { Calendar.current.weekdaySymbols }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 2) {
                ForEach(1...7, id: \.self) { weekday in
                    dayButton(weekday)
                }
            }
            .padding(.vertical, 4)
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    private func dayButton(_ weekday: Int) -> some View {
        let index = weekday - 1
        let isOn = selection.contains(weekday)

        return Button {
            var updated = selection
            if isOn {
                updated.remove(weekday)
            } else {
                updated.insert(weekday)
            }
            // Never allow an enabled daily reminder with no days — that is a
            // silently broken setting.
            selection = updated.isEmpty ? [weekday] : updated
        } label: {
            Text(symbols.indices.contains(index) ? symbols[index] : "")
                .font(.system(.footnote, design: .rounded).weight(.medium))
                .foregroundStyle(isOn ? .white : Theme.inkMuted)
                .frame(width: 44, height: 44)
                .background(
                    Circle().fill(isOn ? Theme.primary : Color.white.opacity(0.6))
                )
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(names.indices.contains(index) ? names[index] : "Day \(weekday)")
        .accessibilityAddTraits(isOn ? [.isButton, .isSelected] : [.isButton])
    }
}

/// The artwork the notification attachment is rendered from, reused here so
/// the screen and the banner are visibly the same object.
struct NotificationArtView: View {
    let kind: NotificationArtKind

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Theme.tapPadGradient)

            Circle()
                .fill(Color.white.opacity(0.10))
                .padding(18)

            Image(systemName: kind == .heart ? "heart.fill" : "clock.fill")
                .font(.system(size: 46, weight: .medium))
                .foregroundStyle(.white)
        }
        .shadow(color: Theme.primary.opacity(0.30), radius: 18, x: 0, y: 6)
    }
}
