# Littletaps

Littletaps is a native SwiftUI iOS app for tracking fetal movement sessions.
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
- Optional local reminders: a daily nudge, an alert when a 2-hour window is
  ending or up, and a gentle check-in after a quiet spell — all off by default
- Siri, Shortcuts, Spotlight and Action button support via App Intents
- A Live Activity with a live count and countdown, and a "+1" button in the
  Dynamic Island that logs a movement without unlocking
- On-device data only: no sign-in, analytics, backend, or network layer.
  Notifications are scheduled locally; there is no push token and no server.

## Development

Requirements:

- Xcode 26 or later
- iOS 26.0 or later
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)

Building against the iOS 26 SDK applies Liquid Glass to system chrome — the
tab bar, `Form` sections, navigation bars and sheets — automatically. The app
does not set `UIDesignRequiresCompatibility`: Apple describes that key as a
temporary aid slated for removal, so opting out would only defer the work.

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

## Pre-Submission Check

Run the full automated check on a Mac with Xcode installed:

```bash
./ios/Scripts/simulator-check.sh              # tests, Release build, bundle checks, simulator launch
./ios/Scripts/simulator-check.sh --archive    # also archive and export an App Store package
./ios/Scripts/simulator-check.sh --device "iPhone SE (3rd generation)"
```

It regenerates the project, runs the unit tests, builds Release, verifies the
bundled `Info.plist`, privacy manifest, app-icon alpha channel, and App Store
screenshot dimensions, then installs the app clean and launches it in both light
and dark appearance so the two screenshots can be compared. Logs and captures
land in `build/simulator-check/`. Hands-on checks it cannot perform are printed
at the end.

## Launch Prep

The working App Store checklist lives in [`TODO.md`](TODO.md). Current in-repo
launch items include:

- `PrivacyInfo.xcprivacy` is bundled with the iOS target.
- Privacy, Terms, and Support links are available from Settings.
- The support page is available at `https://www.babykickcount.com/support` after
  the static site is deployed.
- Focused unit tests cover session state transitions and CSV export escaping.

Still required outside the repo: confirm App Store distribution signing,
archive/upload a Release build, complete App Privacy and age rating, run
TestFlight on physical devices, and upload final screenshots.

## Important Disclaimer

This app is for educational purposes only and is not a medical device. It does
not diagnose conditions or predict outcomes. Always contact your healthcare
provider if fetal movements change abruptly, slow down, stop, or if you have
any concerns about your pregnancy.

## License

MIT
