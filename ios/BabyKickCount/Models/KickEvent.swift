import Foundation
import SwiftData

@Model
final class KickEvent {
    @Attribute(.unique) var id: UUID
    var occurredAt: Date
    var ordinal: Int
    var sourceRaw: String
    var session: KickSession?

    init(
        id: UUID = UUID(),
        occurredAt: Date = .now,
        ordinal: Int,
        source: KickSource = .tap,
        session: KickSession? = nil
    ) {
        self.id = id
        self.occurredAt = occurredAt
        self.ordinal = ordinal
        self.sourceRaw = source.rawValue
        self.session = session
    }

    var source: KickSource {
        get { KickSource(rawValue: sourceRaw) ?? .tap }
        set { sourceRaw = newValue.rawValue }
    }
}
