import SwiftUI

struct TapPad: View {
    let disabled: Bool
    let onTap: () -> Void

    @State private var isPressed = false
    @State private var breath: CGFloat = 1.0

    var body: some View {
        Button(action: tap) {
            ZStack {
                RoundedRectangle(cornerRadius: 40, style: .continuous)
                    .fill(Theme.tapPadGradient)
                    .shadow(color: Theme.primary.opacity(0.30), radius: 24, x: 0, y: 8)

                Circle()
                    .fill(Color.white.opacity(0.10))
                    .frame(width: 140, height: 140)
                    .scaleEffect(breath)

                VStack(spacing: 12) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 64, weight: .regular))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 2)

                    Text("gentle tap")
                        .font(.system(.title2, design: .rounded).weight(.semibold))
                        .foregroundStyle(.white.opacity(0.95))
                        .tracking(1.5)

                    Text("when you feel movement")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.75))
                }
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .opacity(disabled ? 0.5 : 1.0)
        .disabled(disabled)
        .frame(minHeight: 320)
        .onAppear {
            guard !disabled else { return }
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                breath = 1.08
            }
        }
        .accessibilityLabel("Tap to record a kick")
        .accessibilityAddTraits(.isButton)
    }

    private func tap() {
        guard !disabled else { return }
        withAnimation(.easeOut(duration: 0.12)) { isPressed = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            withAnimation(.easeOut(duration: 0.18)) { isPressed = false }
        }
        onTap()
    }
}
