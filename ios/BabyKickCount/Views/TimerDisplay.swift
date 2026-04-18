import SwiftUI

struct TimerDisplay: View {
    let remainingSec: Double
    let timeLimitSec: Int
    let isPaused: Bool
    let isIdle: Bool

    var body: some View {
        VStack(spacing: 4) {
            Text(isIdle ? "Ready when you are" : formatted)
                .font(.system(.title3, design: .monospaced).weight(.medium))
                .foregroundStyle(isPaused ? Theme.inkFaint : Theme.inkMuted)
            Text(isIdle ? "Tap to begin a 2-hour window" : (isPaused ? "Paused" : "Time remaining"))
                .font(.caption)
                .foregroundStyle(Theme.inkFaint)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var formatted: String {
        let total = max(0, Int(remainingSec))
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        return String(format: "%d:%02d:%02d", h, m, s)
    }
}
