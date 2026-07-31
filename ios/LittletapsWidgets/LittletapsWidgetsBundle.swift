import SwiftUI
import WidgetKit

/// The extension exists only to render the session Live Activity. There are no
/// Home Screen or Lock Screen widgets: those read from a timeline provider in
/// this process, which would need the SwiftData store moved into an App Group.
/// A Live Activity is handed its state by value, so it needs none of that.
@main
struct LittletapsWidgetsBundle: WidgetBundle {
    var body: some Widget {
        KickSessionLiveActivity()
    }
}
