import Foundation
import SwiftData
import WatchConnectivity

/// iPhone side of the iPhone <-> Apple Watch sync.
///
/// Everything moves over WatchConnectivity — the system's encrypted channel
/// between a phone and its paired watch. There is no server, no cloud, and no
/// third device anywhere in this path.
///
/// Receives: durable records from the watch (finished sessions and their
/// kicks, via `transferUserInfo`) which are applied to the local store, and
/// transient snapshots (via application context) used to warn before starting
/// a second simultaneous session.
/// Sends: snapshots of this phone's own state, for the same warning on the
/// watch.
@MainActor
final class PhoneSyncService: NSObject, ObservableObject {
    static let shared = PhoneSyncService()

    /// The watch's last reported state; nil until one arrives.
    @Published private(set) var counterpartSnapshot: SnapshotDTO?
    @Published private(set) var isCounterpartReachable = false

    private var container: ModelContainer?
    private var preferences: PreferencesStore?
    private var gate = SnapshotGate()
    private static let seqKey = "BabyKickCount.sync.snapshotSeq"

    private override init() {
        super.init()
    }

    func configure(container: ModelContainer, preferences: PreferencesStore) {
        self.container = container
        self.preferences = preferences
    }

    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    /// True when starting a session here would run alongside a live one on
    /// the watch. Only claimed while the watch is reachable — when it isn't,
    /// the snapshot may be stale, and blocking on it could lock the user out.
    var counterpartHasActiveSession: Bool {
        isCounterpartReachable && counterpartSnapshot?.activeSession != nil
    }

    /// Observes local changes made through the view model. The phone only
    /// publishes snapshots in phase 1; sending durable records to the watch
    /// arrives with the phase 2 mirror.
    func handle(mutation: SessionMutation) {
        publishSnapshot()
    }

    // MARK: - Receiving

    private func receive(context dictionary: [String: Any]) {
        guard let envelope = SyncEnvelope(dictionary: dictionary),
              envelope.type == .snapshot,
              let snapshot = try? envelope.decode(SnapshotDTO.self),
              snapshot.device != .phone,
              gate.admit(snapshot) else {
            return
        }
        counterpartSnapshot = snapshot
    }

    private func receive(durable dictionary: [String: Any]) {
        guard let envelope = SyncEnvelope(dictionary: dictionary),
              let container else {
            return
        }
        do {
            try SyncIngestor(context: container.mainContext).ingest(envelope)
        } catch {
            // Delivery is repeatable and ingest is idempotent; a failed apply
            // is not worth surfacing to someone mid-count.
        }
    }

    // MARK: - Sending

    private func publishSnapshot() {
        guard WCSession.default.activationState == .activated,
              let container, let preferences else {
            return
        }
        let active = (try? SessionStore(context: container.mainContext).activeSession()) ?? nil
        let prefs = preferences.preferences
        let snapshot = SnapshotDTO(
            device: .phone,
            seq: nextSeq(),
            activeSession: active.map(SessionRecordDTO.init),
            liveKickCount: active?.kickCount ?? 0,
            defaultTargetCount: prefs.defaultTargetCount,
            defaultTimeLimitSec: prefs.defaultTimeLimitSec
        )
        guard let envelope = try? SyncEnvelope(.snapshot, payload: snapshot) else { return }
        try? WCSession.default.updateApplicationContext(envelope.dictionary())
    }

    private func nextSeq() -> UInt64 {
        let next = UInt64(max(0, UserDefaults.standard.integer(forKey: Self.seqKey))) + 1
        UserDefaults.standard.set(Int(next), forKey: Self.seqKey)
        return next
    }
}

// MARK: - WCSessionDelegate

extension PhoneSyncService: WCSessionDelegate {
    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        guard activationState == .activated else { return }
        let reachable = session.isReachable
        let pendingContext = session.receivedApplicationContext
        Task { @MainActor in
            self.isCounterpartReachable = reachable
            // Context delivered while the app was not running is handed over
            // here rather than through the delegate callback.
            if !pendingContext.isEmpty {
                self.receive(context: pendingContext)
            }
            self.publishSnapshot()
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        // Required for multi-watch: re-activate so a newly paired watch
        // keeps syncing.
        session.activate()
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        let reachable = session.isReachable
        Task { @MainActor in
            self.isCounterpartReachable = reachable
        }
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveApplicationContext applicationContext: [String: Any]
    ) {
        Task { @MainActor in
            self.receive(context: applicationContext)
        }
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveUserInfo userInfo: [String: Any] = [:]
    ) {
        Task { @MainActor in
            self.receive(durable: userInfo)
        }
    }
}
