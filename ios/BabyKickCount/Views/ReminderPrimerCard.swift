import SwiftUI

/// A one-time, dismissible invitation to set up reminders.
///
/// This is the app's entire discovery story for notifications, and it is
/// deliberately not an onboarding page: onboarding ends on the medical
/// disclaimer, and following that with a permission prompt reads as "this app
/// will alert me about my baby's health". Asking after a first completed
/// session asks at a moment of demonstrated engagement instead.
struct ReminderPrimerCard: View {
    let onDismiss: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "bell.badge")
                .font(.title3)
                .foregroundStyle(Theme.primary)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text("Want a gentle daily reminder?")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(Theme.ink)
                Text("Pick a time that suits you. You can turn it off any time.")
                    .font(.caption)
                    .foregroundStyle(Theme.inkMuted)

                NavigationLink {
                    NotificationSettingsView()
                } label: {
                    Text("Set up reminders")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.primary)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
            }

            Spacer(minLength: 0)

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.inkFaint)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Dismiss reminder suggestion")
        }
        .padding(16)
        .softCard()
    }
}
