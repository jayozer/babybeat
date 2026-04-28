# Littletaps iOS

This is the shipping native SwiftUI app for Littletaps. There is no
Capacitor shell and no bundled web app.

## Requirements

- Xcode 15 or later
- iOS 17.0 or later
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)

## Generate the Xcode project

From this directory:

```bash
xcodegen generate
open BabyKickCount.xcodeproj
```

Pick a development team in **Signing & Capabilities**, choose an iPhone
simulator or device, and run.

## Project layout

```text
ios/
├── project.yml
└── BabyKickCount/
    ├── App/              SwiftUI app entry point and SwiftData model container
    ├── DesignSystem/     Theme colors and shared styling
    ├── Models/           KickSession, KickEvent, preferences, and enums
    ├── Services/         State machine, persistence, feedback, and export
    ├── ViewModels/       Session interaction model
    ├── Views/            SwiftUI screens and components
    ├── Resources/        Asset catalog and app icon
    └── Info.plist
```

## App Store notes

- Bundle identifier: `com.babykickcount.app`
- Display name: `Littletaps`
- Version: `1.0.0`
- Build: `1`
- Encryption export flag is set to `false`.
- Data is stored on device with SwiftData/UserDefaults.
- The app has no network layer, analytics SDK, account system, or web view.

## Medical disclaimer

This app is for educational purposes only. It is not a medical device and does
not diagnose conditions or predict outcomes. Users should contact a healthcare
provider with concerns about fetal movement.
