import AppIntents
import SwiftUI

struct KickCountQueryIntent: AppIntent {
    static let title: LocalizedStringResource = "Taps so far"
    static let description = IntentDescription(
        "Reports how many movements you've counted in the session that's running.",
        categoryName: "Counting"
    )

    static let openAppWhenRun = false

    func perform() async throws -> some IntentResult & ReturnsValue<Int> & ProvidesDialog & ShowsSnippetView {
        let snapshot = try await MainActor.run { () throws -> (count: Int, target: Int, remaining: Int) in
            guard let viewModel = IntentBridge.session else {
                throw LittletapsIntentError.unavailable
            }
            guard viewModel.isActive || viewModel.isPaused else {
                throw LittletapsIntentError.noActiveSession
            }
            return (
                viewModel.kickCount,
                viewModel.targetCount,
                Int(viewModel.remainingSec.rounded())
            )
        }

        let minutes = max(0, snapshot.remaining / 60)
        return .result(
            value: snapshot.count,
            dialog: "\(NotificationPlanner.tapCount(snapshot.count)), about \(minutes) minutes left.",
            view: KickCountSnippetView(
                count: snapshot.count,
                target: snapshot.target,
                minutesRemaining: minutes
            )
        )
    }
}

/// The card Siri and the Shortcuts app show alongside the spoken answer — one
/// of the few places outside the app where the palette gets to appear.
struct KickCountSnippetView: View {
    let count: Int
    let target: Int
    let minutesRemaining: Int

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().fill(Theme.tapPadGradient)
                Text("\(count)")
                    .font(.system(size: 30, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .frame(width: 72, height: 72)

            VStack(alignment: .leading, spacing: 4) {
                Text("of \(target) movements")
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(Theme.ink)
                Text("about \(minutesRemaining) minutes left")
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkMuted)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .softCard()
    }
}
