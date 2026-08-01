import SwiftUI

/// The artwork a notification carries as its attachment thumbnail, and the
/// hero on the Reminders screen — the same view in both places so the banner
/// and the settings screen are visibly the same object.
///
/// Drawn from `Theme` rather than bundled as an image so the palette stays in
/// one file and the repo gains no binary assets.
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
    }
}
