import SwiftUI

struct CountDisplay: View {
    let currentCount: Int
    let targetCount: Int

    var body: some View {
        VStack(spacing: 8) {
            Text("\(currentCount)")
                .font(.system(size: 72, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.primaryDark)
                .contentTransition(.numericText())
                .animation(.spring(duration: 0.3), value: currentCount)

            Text("of \(targetCount) movements")
                .font(.subheadline)
                .foregroundStyle(Theme.inkFaint)

            ProgressView(value: Double(min(currentCount, targetCount)), total: Double(targetCount))
                .tint(Theme.primary)
                .frame(maxWidth: 220)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}
