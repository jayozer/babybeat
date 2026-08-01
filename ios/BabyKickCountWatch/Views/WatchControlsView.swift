import SwiftUI

/// Lifecycle controls, one swipe left of the tap surface — deliberately off
/// the tap page so resting taps can never hit Undo or End.
struct WatchControlsView: View {
    @ObservedObject var viewModel: SessionViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                if viewModel.isActive || viewModel.isPaused {
                    Button {
                        viewModel.undo()
                    } label: {
                        Label("Undo", systemImage: "arrow.uturn.backward")
                    }
                    .disabled(viewModel.kickCount == 0)

                    if viewModel.isPaused {
                        Button {
                            viewModel.resume()
                        } label: {
                            Label("Resume", systemImage: "play.fill")
                        }
                        .tint(Theme.primary)
                    } else {
                        Button {
                            viewModel.pause()
                        } label: {
                            Label("Pause", systemImage: "pause.fill")
                        }
                    }

                    Button(role: .destructive) {
                        viewModel.endEarly()
                    } label: {
                        Label("End Session", systemImage: "stop.fill")
                    }
                } else {
                    Image(systemName: "heart.fill")
                        .font(.title3)
                        .foregroundStyle(Theme.primary)
                    Text("Swipe back and tap the heart to start a session.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .navigationTitle("Session")
    }
}
