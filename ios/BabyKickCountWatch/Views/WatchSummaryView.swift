import SwiftUI

/// Shown when a session reaches a terminal state: outcome, count, duration,
/// and a star rating. Notes stay on the iPhone — dictating into a summary
/// screen is friction nobody needs at 3am.
struct WatchSummaryView: View {
    @ObservedObject var viewModel: SessionViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                Text(headline)
                    .font(.headline)
                    .foregroundStyle(Theme.primary)

                Text(summaryLine)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                ratingRow
                    .padding(.vertical, 4)

                Text("Add notes on iPhone")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Button("Start New Session") {
                    viewModel.resetForNewSession()
                }
                .tint(Theme.primary)
            }
        }
        .navigationTitle("Summary")
    }

    private var headline: String {
        switch viewModel.session?.status {
        case .complete: return "Complete!"
        case .timeout: return "Time's up"
        default: return "Session ended"
        }
    }

    private var summaryLine: String {
        let count = viewModel.kickCount
        let movements = count == 1 ? "movement" : "movements"
        guard let duration = viewModel.session?.durationSec else {
            return "\(count) \(movements)"
        }
        let minutes = max(1, Int((duration / 60).rounded()))
        return "\(count) \(movements) in \(minutes) min"
    }

    private var ratingRow: some View {
        let current = viewModel.session?.strengthRating ?? 0
        return HStack(spacing: 4) {
            ForEach(1...5, id: \.self) { star in
                Button {
                    viewModel.saveDetails(
                        rating: star,
                        notes: viewModel.session?.notes ?? ""
                    )
                } label: {
                    Image(systemName: star <= current ? "star.fill" : "star")
                        .foregroundStyle(star <= current ? Theme.primary : Color.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Rate movement strength \(star) of 5")
            }
        }
        .accessibilityElement(children: .contain)
    }
}
