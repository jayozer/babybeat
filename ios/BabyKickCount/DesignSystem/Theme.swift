import SwiftUI

enum Theme {
    static let primary = Color(red: 0x5A / 255, green: 0x8F / 255, blue: 0x5A / 255)
    static let primaryDark = Color(red: 0x47 / 255, green: 0x73 / 255, blue: 0x47 / 255)
    static let primaryLight = Color(red: 0x7B / 255, green: 0xAB / 255, blue: 0x7B / 255)
    static let primarySoft = Color(red: 0xA8 / 255, green: 0xC9 / 255, blue: 0xA8 / 255)

    static let ink = Color(red: 0x49 / 255, green: 0x4D / 255, blue: 0x49 / 255)
    static let inkMuted = Color(red: 0x6B / 255, green: 0x73 / 255, blue: 0x6B / 255)
    static let inkFaint = Color(red: 0x85 / 255, green: 0x8E / 255, blue: 0x85 / 255)

    static let surface = Color.white.opacity(0.7)
    static let surfaceStrong = Color.white.opacity(0.85)
    static let divider = Color(red: 0xE8 / 255, green: 0xF0 / 255, blue: 0xE8 / 255)

    static let timeoutAmber = Color(red: 0xD4 / 255, green: 0xA3 / 255, blue: 0x73 / 255)
    static let endedLavender = Color(red: 0xB8 / 255, green: 0xA9 / 255, blue: 0xC9 / 255)

    static let background = LinearGradient(
        colors: [
            Color(red: 0xFE / 255, green: 0xFD / 255, blue: 0xFB / 255),
            Color(red: 0xFD / 255, green: 0xF9 / 255, blue: 0xF3 / 255),
            Color(red: 0xF6 / 255, green: 0xF9 / 255, blue: 0xF6 / 255)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let tapPadGradient = LinearGradient(
        colors: [primarySoft, primaryLight, primary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

extension View {
    func softCard() -> some View {
        self
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: Theme.primary.opacity(0.08), radius: 20, x: 0, y: 4)
    }
}
