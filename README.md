# Baby Kick Count

Baby Kick Count is a native SwiftUI iOS app for tracking fetal movement sessions.
The web app and Capacitor wrapper have been removed; the supported App Store
build now lives entirely in [`ios/`](ios/).

## Features

- One-tap kick logging with haptic and synthesized audio feedback
- 2-hour session window targeting 10 movements
- Pause, resume, undo, timeout, and end-early session states
- SwiftData persistence for sessions and kick timestamps
- Calendar-based history and session review
- CSV export through the native iOS share sheet
- First-run onboarding, settings, and educational safety guidance
- On-device data only: no sign-in, analytics, backend, or network layer

## Development

Requirements:

- Xcode 15 or later
- iOS 17.0 or later
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)

Generate and open the Xcode project:

```bash
cd ios
xcodegen generate
open BabyKickCount.xcodeproj
```

Build from the command line:

```bash
xcodebuild \
  -project ios/BabyKickCount.xcodeproj \
  -scheme BabyKickCount \
  -destination 'generic/platform=iOS Simulator' \
  build
```

Before submitting to the App Store, set the signing team in Xcode and confirm
the bundle identifier, version, build number, and app icon are final.

## Important Disclaimer

This app is for educational purposes only and is not a medical device. It does
not diagnose conditions or predict outcomes. Always contact your healthcare
provider if fetal movements change abruptly, slow down, stop, or if you have
any concerns about your pregnancy.

## License

MIT
