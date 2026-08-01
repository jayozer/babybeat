import Foundation

/// A change the view model just made to the local store. The sync service on
/// each platform observes these to decide what to publish to the counterpart
/// device — the view model itself stays transport-agnostic.
enum SessionMutation {
    case started(KickSession)
    case kickRegistered(session: KickSession, event: KickEvent)
    /// Carries the removed event's id rather than the deleted model, because
    /// a deleted `@Model` must not be touched after the save.
    case kickUndone(session: KickSession, eventID: UUID)
    /// Pause, resume, or any transition into a terminal state.
    case lifecycleChanged(KickSession)
    /// Rating or notes were edited on the summary screen.
    case detailsSaved(KickSession)
}
