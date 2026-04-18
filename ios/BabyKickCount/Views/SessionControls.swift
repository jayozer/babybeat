import SwiftUI

struct SessionControls: View {
    let canUndo: Bool
    let isPaused: Bool
    let onUndo: () -> Void
    let onPause: () -> Void
    let onResume: () -> Void
    let onEnd: () -> Void

    @State private var confirmingEnd = false

    var body: some View {
        HStack(spacing: 12) {
            controlButton(title: "Undo", systemImage: "arrow.uturn.backward", disabled: !canUndo, action: onUndo)

            if isPaused {
                controlButton(title: "Resume", systemImage: "play.fill", action: onResume)
            } else {
                controlButton(title: "Pause", systemImage: "pause.fill", action: onPause)
            }

            controlButton(title: "End", systemImage: "stop.fill", role: .destructive) {
                confirmingEnd = true
            }
        }
        .confirmationDialog(
            "End this session?",
            isPresented: $confirmingEnd,
            titleVisibility: .visible
        ) {
            Button("End session", role: .destructive, action: onEnd)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your progress will be saved.")
        }
    }

    @ViewBuilder
    private func controlButton(
        title: String,
        systemImage: String,
        disabled: Bool = false,
        role: ButtonRole? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(role: role, action: action) {
            VStack(spacing: 6) {
                Image(systemName: systemImage).font(.system(size: 18, weight: .semibold))
                Text(title).font(.caption).fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .foregroundStyle(role == .destructive ? Theme.endedLavender : Theme.primaryDark)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.45 : 1.0)
    }
}
