import Foundation

/// A session reduced to the fields the merge rules need, so the rules stay
/// pure functions that unit tests can exercise without a model container.
struct SessionMergeCandidate: Equatable {
    let id: UUID
    let startedAt: Date?
    let endedAt: Date?
    let isTerminal: Bool

    init(id: UUID, startedAt: Date?, endedAt: Date?, isTerminal: Bool) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.isTerminal = isTerminal
    }

    init(_ session: KickSession) {
        self.id = session.id
        self.startedAt = session.startedAt
        self.endedAt = session.endedAt
        self.isTerminal = session.status.isTerminal
    }
}

/// Deterministic rules for reconciling sessions created on two devices while
/// they were disconnected. Both devices run the same pure functions on the
/// same inputs, so their stores converge without any coordination.
///
/// Phase 1 ships these rules with tests but does not yet apply the
/// record-deleting merge; overlapping offline sessions simply appear as two
/// history entries until the phase 2 mirror work wires this in.
enum SessionMerge {
    /// Two sessions conflict when their `[startedAt, endedAt ?? now]` windows
    /// intersect and at least one of them is still live. Two terminal
    /// sessions never conflict — both are finished records, and merging them
    /// would double-count movements.
    static func conflict(
        _ a: SessionMergeCandidate,
        _ b: SessionMergeCandidate,
        at now: Date
    ) -> Bool {
        guard a.id != b.id,
              !(a.isTerminal && b.isTerminal),
              let aStart = a.startedAt,
              let bStart = b.startedAt else {
            return false
        }
        let aEnd = a.endedAt ?? now
        let bEnd = b.endedAt ?? now
        return aStart <= bEnd && bStart <= aEnd
    }

    /// The record that survives a merge: earlier `startedAt` wins, with the
    /// lexicographically smaller id as a tiebreak. A session that has not
    /// started loses to one that has.
    static func survivorID(
        _ a: SessionMergeCandidate,
        _ b: SessionMergeCandidate
    ) -> UUID {
        switch (a.startedAt, b.startedAt) {
        case let (aStart?, bStart?):
            if aStart != bStart {
                return aStart < bStart ? a.id : b.id
            }
            return a.id.uuidString < b.id.uuidString ? a.id : b.id
        case (.some, .none):
            return a.id
        case (.none, .some):
            return b.id
        case (.none, .none):
            return a.id.uuidString < b.id.uuidString ? a.id : b.id
        }
    }

    /// Reassigns 1-based ordinals by `occurredAt` (id as tiebreak) and
    /// returns the resulting count. Ordinals are derived data everywhere the
    /// sync engine touches events, so kicks logged on both devices interleave
    /// correctly no matter which order they arrive in.
    @discardableResult
    static func renumber(_ events: [KickEvent]) -> Int {
        let sorted = events.sorted { lhs, rhs in
            if lhs.occurredAt != rhs.occurredAt {
                return lhs.occurredAt < rhs.occurredAt
            }
            return lhs.id.uuidString < rhs.id.uuidString
        }
        for (index, event) in sorted.enumerated() {
            event.ordinal = index + 1
        }
        return sorted.count
    }
}
