# Baby Kick Count — iOS

Native SwiftUI port of the [Baby Kick Count](../README.md) web app. Feature-parity with the web version: one-tap kick logging with synthesized sounds, 2-hour timer window, pause/resume/undo, session summary with strength rating + notes, calendar-based history, CSV export, and on-device persistence.

## Requirements

- Xcode 15 or later
- iOS 17.0+ deployment target
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`) to generate the Xcode project

## Generate the Xcode project

From the `ios/` directory:

```bash
xcodegen generate
open BabyKickCount.xcodeproj
```

Pick a development team in **Signing & Capabilities**, choose an iPhone simulator or device, and run.

If you prefer not to install XcodeGen, create an empty Xcode iOS App project named `BabyKickCount` targeting iOS 17, delete the default files, drag `ios/BabyKickCount/` into the project, and point the target's Info.plist at `BabyKickCount/Info.plist`.

## Project layout

```
ios/
├── project.yml                    XcodeGen spec
└── BabyKickCount/
    ├── App/BabyKickCountApp.swift Entry point + SwiftData model container
    ├── Models/                    KickSession, KickEvent, UserPreferences, enums
    ├── Services/                  State machine, SwiftData store, preferences, feedback, export
    ├── ViewModels/                SessionViewModel (tap / pause / resume / auto-complete / timeout)
    ├── Views/                     SwiftUI screens and components
    ├── DesignSystem/              Theme colors and card styling
    ├── Resources/Assets.xcassets  AppIcon, AccentColor, LaunchBackground
    └── Info.plist
```

## Feature parity with web

| Web feature | iOS equivalent |
| --- | --- |
| Tap pad + ripple + breathing | `Views/TapPad.swift` using SwiftUI animations |
| Web Audio synth sounds (click/pop/heartbeat/bubble) | `Services/FeedbackService.swift` generates PCM buffers via `AVAudioEngine` |
| `navigator.vibrate` | `UIImpactFeedbackGenerator` (medium) |
| Wake Lock API | `UIApplication.shared.isIdleTimerDisabled` toggled by session state |
| Dexie/IndexedDB | SwiftData (`@Model` on `KickSession` and `KickEvent`) |
| Preferences in IndexedDB | JSON-encoded `UserPreferences` in `UserDefaults` |
| Session state machine | `Services/SessionStateMachine.swift` (idle → active → paused/complete/timeout/ended_early) |
| Calendar heatmap | `Views/CalendarGridView.swift` |
| CSV export | `Services/ExportService.swift` + `UIActivityViewController` share sheet |
| Onboarding modal | `Views/OnboardingView.swift` (first-launch flag in `UserPreferences`) |

## Notes

- The app icon asset is a placeholder — drop a 1024×1024 PNG into `Resources/Assets.xcassets/AppIcon.appiconset/` before shipping.
- Sounds are synthesized at runtime to match the web app's Web Audio implementation. No audio files are bundled.
- All data stays on-device. There is no network layer, analytics, or sign-in.

## Medical disclaimer

This app is for educational purposes only. It is not a medical device and does not diagnose conditions or predict outcomes. Always consult a healthcare provider with concerns about fetal movement.
