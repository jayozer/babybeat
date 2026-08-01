import Foundation
import SwiftData
import WatchConnectivity

/// Watch side of the iPhone <-> Apple Watch sync.
///
/// Everything moves over WatchConnectivity — the system's encrypted channel
/// between a watch and its paired phone. There is no server, no cloud, and no
/// third device anywhere in this path.
///
/// Sends: transient snapshots of this watch's state on every local change
/// (application context), and the durable record of every finished session —
/// a `sessionUpsert` followed by its kicks — via `transferUserInfo`, whose
/// queue survives reboots and delivers even when the phone is in a different
/// room. Undone kicks travel as tombstones so a queued event cannot
/// resurrect them.
/// Receives: the phone's snapshots (to warn before starting a second
/// simultaneous session) and any durable records the phone sends (phase 2).
@MainActor
final class WatchSyncService: NSObject, ObservableObject {
    static let shared = WatchSyncService()

    /// The phone's last reported state; nil until one arrives.
    @Published private(set) var counterpartSnapshot: SnapshotDTO?
    @Published private(set) var isCounterpartReachable = false

    private var container: ModelContainer?
    private var preferences: PreferencesStore?
    private var gate = SnapshotGate()
    private static let seqKey = "BabyKickCount.sync.snapshotSeq"
    private static let kickBatchChunkSize = 200

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
    /// the phone. Only claimed while the phone is reachable — when it isn't,
    /// the snapshot may be stale, and the whole point of the watch app is
    /// counting with the phone out of reach.
    var counterpartHasActiveSession: Bool {
        isCounterpartReachable && counterpartSnapshot?.activeSession != nil
    }

    /// Observes local changes made through the view model.
    func handle(mutation: SessionMutation) {
        publishSnapshot()
        switch mutation {
        case .started, .kickRegistered:
            break
        case .kickUndone(let session, let eventID):
            sendDurable(.kickRemove, KickRemoveDTO(sessionID: session.id, eventID: eventID))
        case .lifecycleChanged(let session):
            if session.status.isTerminal {
                sendTerminalRecord(session)
            }
        case .detailsSaved(let session):
            // The rating is usually set after the terminal record has been
            // queued, so re-send the (idempotent) upsert with it included.
            if session.status.isTerminal {
                sendDurable(.sessionUpsert, SessionRecordDTO(session))
            }
        }
    }

    // MARK: - Receiving

    private func receive(context dictionary: [String: Any]) {
        guard let envelope = SyncEnvelope(dictionary: dictionary),
              envelope.type == .snapshot,
              let snapshot = try? envelope.decode(SnapshotDTO.self),
              snapshot.device != .watch,
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

    /// The guaranteed record of a finished session: the full session row plus
    /// every kick, all through the durable transfer queue. A normal session
    /// is ten kicks, so chunking only matters as a payload-size guard.
    private func sendTerminalRecord(_ session: KickSession) {
        sendDurable(.sessionUpsert, SessionRecordDTO(session))
        let kicks = session.events.map { KickRecordDTO(sessionID: session.id, event: $0) }
        var start = 0
        while start < kicks.count {
            let end = min(start + Self.kickBatchChunkSize, kicks.count)
            sendDurable(.kickBatch, KickBatchDTO(kicks: Array(kicks[start..<end])))
            start = end
        }
    }

    private func sendDurable<T: Encodable>(_ type: SyncMessageType, _ payload: T) {
        guard WCSession.default.activationState == .activated,
              let envelope = try? SyncEnvelope(type, payload: payload) else {
            return
        }
        WCSession.default.transferUserInfo(envelope.dictionary())
    }

    private func publishSnapshot() {
        guard WCSession.default.activationState == .activated,
              let container, let preferences else {
            return
        }
        let active = (try? SessionStore(context: container.mainContext).activeSession()) ?? nil
        let prefs = preferences.preferences
        let snapshot = SnapshotDTO(
            device: .watch,
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

extension WatchSyncService: WCSessionDelegate {
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
