import SwiftUI

/// The whole screen is the button. The first tap on an idle screen starts
/// the session and logs the first movement, exactly like the iPhone tap pad.
struct WatchTapSurface: View {
    @ObservedObject var viewModel: SessionViewModel
    let blockedByPhone: Bool

    @Environment(\.isLuminanceReduced) private var isLuminanceReduced

    private var isDisabled: Bool {
        viewModel.isPaused || blockedByPhone
    }

    var body: some View {
        Button(action: viewModel.tap) {
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Theme.tapPadGradient)
                    .opacity(isDisabled ? 0.5 : 1)

                content
            }
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .accessibilityLabel(accessibilityText)
    }

    @ViewBuilder
    private var content: some View {
        if blockedByPhone {
            statusMessage(
                icon: "iphone",
                text: "A session is in progress on your iPhone"
            )
        } else if viewModel.isPaused {
            statusMessage(icon: "pause.fill", text: "Paused")
        } else if viewModel.session == nil {
            VStack(spacing: 6) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(.white)
                Text("Tap to begin")
                    .font(.headline)
                    .foregroundStyle(.white)
                Text("\(viewModel.targetCount) movements")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.85))
            }
        } else {
            VStack(spacing: 2) {
                Text(remainingText)
                    .font(.footnote.monospacedDigit())
                    .foregroundStyle(.white.opacity(0.85))
                Text("\(viewModel.kickCount)")
                    .font(.system(size: 54, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(.white)
                Text("of \(viewModel.targetCount)")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
    }

    private func statusMessage(icon: String, text: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.white)
            Text(text)
                .font(.footnote)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 8)
    }

    /// In the always-on dimmed state the app is not ticking every second, so
    /// showing seconds would display a stale value; minutes are honest.
    private var remainingText: String {
        let total = Int(viewModel.remainingSec.rounded())
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        if isLuminanceReduced {
            return hours > 0
                ? String(format: "%d:%02d left", hours, minutes)
                : "\(minutes) min left"
        }
        return hours > 0
            ? String(format: "%d:%02d:%02d", hours, minutes, seconds)
            : String(format: "%02d:%02d", minutes, seconds)
    }

    private var accessibilityText: String {
        if blockedByPhone { return "Counting on iPhone" }
        if viewModel.isPaused { return "Paused" }
        if viewModel.session == nil { return "Tap to begin counting" }
        return "Log a movement. \(viewModel.kickCount) of \(viewModel.targetCount) so far"
    }
}
