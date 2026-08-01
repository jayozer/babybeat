import SwiftUI
import UIKit

/// Renders `NotificationArtView` to a PNG that can be attached to a
/// notification, which is what puts a thumbnail on the banner.
///
/// Two constraints shape this. `UNNotificationAttachment` cannot take an asset
/// catalog image — it needs a file URL — and it **moves** the file it is given
/// into the system's attachment store, so the same URL cannot be handed out
/// twice. Hence: render once, cache the bytes in memory, and write a fresh
/// throwaway file per attachment.
@MainActor
enum NotificationArtRenderer {
    private static var cache: [NotificationArtKind: Data] = [:]

    /// Large enough for the full-width expanded presentation; the collapsed
    /// banner downsamples it.
    private static let side: CGFloat = 200
    private static let scale: CGFloat = 3

    static func attachmentURL(for kind: NotificationArtKind) -> URL? {
        guard let data = pngData(for: kind) else { return nil }

        let url = FileManager.default.temporaryDirectory
            .appending(path: "lt-art-\(kind.rawValue)-\(UUID().uuidString).png")
        do {
            try data.write(to: url)
            return url
        } catch {
            // Non-fatal: the notification is still perfectly usable without a
            // thumbnail.
            return nil
        }
    }

    private static func pngData(for kind: NotificationArtKind) -> Data? {
        if let cached = cache[kind] { return cached }

        let renderer = ImageRenderer(
            content: NotificationArtView(kind: kind)
                .frame(width: side, height: side)
        )
        renderer.scale = scale

        guard let data = renderer.uiImage?.pngData() else { return nil }
        cache[kind] = data
        return data
    }
}
