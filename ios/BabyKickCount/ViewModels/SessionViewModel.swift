import Foundation
import SwiftData
import SwiftUI
#if os(iOS)
import UIKit
#endif

@MainActor
final class SessionViewModel: ObservableObject {
    @Published private(set) var session: KickSession?
    @Published private(set) var elapsedSec: Double = 0
    @Published private(set) var errorMessage: String?

    /// The sync service on each platform observes local changes through this
    /// hook; the view model itself knows nothing about WatchConnectivity.
    private let onMutation: ((SessionMutation) -> Void)?

    private let store: SessionStore
    private let preferences: PreferencesStore
    private let feedback: FeedbackProviding
    private var timerTask: Task<Void, Never>?

    init(
        store: SessionStore,
        preferences: PreferencesStore,
        feedback: FeedbackProviding,
        onMutation: ((SessionMutation) -> Void)? = nil
    ) {
        self.store = store
        self.preferences = preferences
        self.feedback = feedback
        self.onMutation = onMutation
        do {
            if let existing = try store.activeSession() {
                self.session = existing
                startTicking()
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    /// The ticking loop is otherwise only stopped by `stopTicking()`. The view
    /// model lives for the app's lifetime today, but nothing enforces that, and
    /// a loop left running would sleep forever against a nil `self`.
    deinit {
        timerTask?.cancel()
    }

    // MARK: - Computed

    var kickCount: Int { session?.kickCount ?? 0 }
    var targetCount: Int { session?.targetCount ?? preferences.preferences.defaultTargetCount }
    var isActive: Bool { session?.status == .active }
    var isPaused: Bool { session?.status == .paused }
    var isFinished: Bool { session?.status.isTerminal == true }

    var remainingSec: Double {
        guard let session else { return Double(preferences.preferences.defaultTimeLimitSec) }
        if isFinished {
            return max(0, Double(session.timeLimitSec) - (session.durationSec ?? 0))
        }
        return SessionStateMachine.remainingSeconds(for: session)
    }

    // MARK: - Intents

    func tap() {
        do {
            let target: KickSession
            if let session {
                target = session
            } else {
                target = try ensureSession()
            }
            if target.status == .idle {
                try SessionStateMachine.start(target)
                startTicking()
                onMutation?(.started(target))
            }
            guard target.status == .active else { return }
            let event = try store.registerKick(in: target)
            feedback.kickFeedback(
                sound: preferences.preferences.soundOption,
                vibrationEnabled: preferences.preferences.vibrationEnabled
            )
            session = target
            onMutation?(.kickRegistered(session: target, event: event))
            if SessionStateMachine.shouldAutoComplete(target) {
                try SessionStateMachine.complete(target)
                try store.save()
                stopTicking()
                feedback.outcomeFeedback(target.status)
                onMutation?(.lifecycleChanged(target))
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func undo() {
        guard let session else { return }
        do {
            if let removedID = try store.undoLastKick(in: session) {
                feedback.undoFeedback()
                onMutation?(.kickUndone(session: session, eventID: removedID))
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func pause() {
        guard let session else { return }
        do {
            try SessionStateMachine.pause(session)
            try store.save()
            onMutation?(.lifecycleChanged(session))
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func resume() {
        guard let session else { return }
        do {
            try SessionStateMachine.resume(session)
            try store.save()
            onMutation?(.lifecycleChanged(session))
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func endEarly() {
        guard let session else { return }
        do {
            try SessionStateMachine.endEarly(session)
            try store.save()
            stopTicking()
            feedback.outcomeFeedback(session.status)
            onMutation?(.lifecycleChanged(session))
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveDetails(rating: Int?, notes: String) {
        guard let session else { return }
        session.strengthRating = rating
        session.notes = notes.isEmpty ? nil : notes
        do {
            try store.save()
            onMutation?(.detailsSaved(session))
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func resetForNewSession() {
        session = nil
        elapsedSec = 0
    }

    func dismissError() { errorMessage = nil }

    // MARK: - Private

    private func ensureSession() throws -> KickSession {
        let prefs = preferences.preferences
        let new = try store.createSession(
            targetCount: prefs.defaultTargetCount,
            timeLimitSec: prefs.defaultTimeLimitSec
        )
        session = new
        return new
    }

    private func startTicking() {
        stopTicking()
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.tick()
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }
    }

    private func stopTicking() {
        timerTask?.cancel()
        timerTask = nil
    }

    private func tick() async {
        guard let session else { return }
        elapsedSec = SessionStateMachine.elapsedSeconds(for: session)
        if SessionStateMachine.shouldTimeout(session) {
            do {
                try SessionStateMachine.timeout(session)
                try store.save()
                stopTicking()
                feedback.outcomeFeedback(session.status)
                onMutation?(.lifecycleChanged(session))
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Wake lock

    /// iPhone-only: the watch has no idle-timer API and manages its own
    /// display, so this is a no-op there.
    func applyWakeLock() {
        #if os(iOS)
        UIApplication.shared.isIdleTimerDisabled =
            preferences.preferences.keepScreenAwake && (isActive || isPaused)
        #endif
    }
}
