import SwiftUI
import SwiftData

struct SessionView: View {
    @EnvironmentObject private var preferences: PreferencesStore
    @StateObject private var viewModel: SessionViewModel

    @State private var showSummary = false
    @State private var dismissedSummaryForSessionID: UUID?

    init(context: ModelContext, preferences: PreferencesStore) {
        let store = SessionStore(context: context)
        _viewModel = StateObject(wrappedValue: SessionViewModel(store: store, preferences: preferences))
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    header

                    if let error = viewModel.errorMessage {
                        errorBanner(error)
                    }

                    CountDisplay(currentCount: viewModel.kickCount, targetCount: viewModel.targetCount)

                    TimerDisplay(
                        remainingSec: viewModel.remainingSec,
                        timeLimitSec: preferences.preferences.defaultTimeLimitSec,
                        isPaused: viewModel.isPaused,
                        isIdle: viewModel.session == nil
                    )

                    TapPad(disabled: viewModel.isPaused || viewModel.isFinished) {
                        viewModel.tap()
                    }

                    if viewModel.isActive || viewModel.isPaused {
                        SessionControls(
                            canUndo: viewModel.kickCount > 0,
                            isPaused: viewModel.isPaused,
                            onUndo: viewModel.undo,
                            onPause: viewModel.pause,
                            onResume: viewModel.resume,
                            onEnd: viewModel.endEarly
                        )
                    }

                    if viewModel.isFinished {
                        Button {
                            viewModel.resetForNewSession()
                            dismissedSummaryForSessionID = nil
                        } label: {
                            Text("Start New Session")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Theme.primary, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
            }
        }
        .onAppear {
            FeedbackService.shared.prepare()
            viewModel.applyWakeLock()
        }
        .onChange(of: viewModel.isActive) { _, _ in viewModel.applyWakeLock() }
        .onChange(of: viewModel.isPaused) { _, _ in viewModel.applyWakeLock() }
        .onChange(of: viewModel.session?.status) { _, newStatus in
            guard let newStatus, newStatus.isTerminal,
                  let id = viewModel.session?.id,
                  dismissedSummaryForSessionID != id else {
                return
            }
            showSummary = true
        }
        .sheet(isPresented: $showSummary) {
            if let session = viewModel.session {
                dismissedSummaryForSessionID = session.id
            }
        } content: {
            if let session = viewModel.session {
                SessionSummarySheet(
                    session: session,
                    onSave: viewModel.saveDetails,
                    onStartNew: {
                        viewModel.resetForNewSession()
                        dismissedSummaryForSessionID = nil
                    }
                )
            }
        }
    }

    private var header: some View {
        VStack(spacing: 4) {
            Text("Baby Kick Count")
                .font(.system(.title2, design: .rounded).weight(.semibold))
                .foregroundStyle(Theme.ink)
            Text("Track your baby's movements gently")
                .font(.footnote)
                .foregroundStyle(Theme.inkFaint)
        }
    }

    private func errorBanner(_ message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Theme.endedLavender)
            Text(message).font(.footnote).foregroundStyle(Theme.ink)
            Spacer()
            Button("Dismiss", action: viewModel.dismissError).font(.caption)
        }
        .padding(12)
        .background(Color(red: 0xF9 / 255, green: 0xF8 / 255, blue: 0xFC / 255), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
