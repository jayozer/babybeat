# Apple App Store Launch TODO

Generated on April 26, 2026 after reviewing the native iOS app, the production website, the user-provided App Store submission checklist, and current Apple documentation.

## Current State

- App target: native SwiftUI iPhone app in `ios/`.
- Bundle identifier: `com.babykickcount.app`.
- App Store Connect app ID: `6763963304`.
- App Store product name: `Littletaps - Baby Kick Count`.
- Display name: `Littletaps`.
- Version/build: `1.0` / `1`.
- Deployment target: iOS 17.0.
- Device family: iPhone only.
- Simulator test status: passed with `xcodebuild -project ios/BabyKickCount.xcodeproj -scheme BabyKickCount -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /tmp/babybeat-derived-launch-review test`.
- Release simulator build status: passed with `xcodebuild -project ios/BabyKickCount.xcodeproj -scheme BabyKickCount -configuration Release -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/babybeat-release-derived-launch-review build`.
- Device archive status: passed with `xcodebuild -project ios/BabyKickCount.xcodeproj -scheme BabyKickCount -configuration Release -destination generic/platform=iOS -archivePath /tmp/babybeat-launch-archive/Littletaps-1.0.xcarchive archive`.
- Pricing and availability: saved as free (`$0.00`) with all 175 countries/regions available on app release.
- App data model: SwiftData sessions/events and UserDefaults preferences, all local.
- Privacy manifest: `ios/BabyKickCount/PrivacyInfo.xcprivacy` is bundled and declares `UserDefaults` reason `CA92.1`, tracking false, and no collected data.
- Network/account/payment review: no network layer, no web view, no login, no analytics SDK, no StoreKit, no Stripe, no ads.
- Website: static launch pages now include `/privacy`, `/terms`, `/support`, `/llms.txt`, clean canonical URLs, and no production Tweaks/React/Babel scripts.

## P0: Must Finish Before First App Store Submission

- [x] Create the App Store Connect app record with the exact bundle ID `com.babykickcount.app`, platform iOS, primary language, SKU, and final app name. Created with Apple app ID `6763963304`; App Store Connect shows `Littletaps - Baby Kick Count`.
- [ ] Set the signing team in Xcode, confirm App Store distribution signing, archive a Release build, upload through Xcode/App Store Connect, and verify the uploaded build appears in App Store Connect. Local generic iOS archive now succeeds; App Store export/upload still needs distribution provisioning to be repaired/refreshed in Xcode.
- [x] Add `PrivacyInfo.xcprivacy` to the iOS target. The app uses `UserDefaults` in `PreferencesStore.swift`, so declare `NSPrivacyAccessedAPICategoryUserDefaults` with reason `CA92.1` for app-only preferences. Set tracking to false and declare no collected data unless a new network/data feature is added.
- [x] Add easily accessible in-app links for Privacy Policy, Terms, and Support, likely under Settings -> Information & Help. Apple requires the privacy policy link in App Store Connect metadata and inside the app.
- [x] Use `https://www.babykickcount.com/privacy` as the App Store Connect Privacy Policy URL because it returns `200` directly. Saved in App Store Connect App Privacy.
- [x] Create or designate a Support URL that includes real contact information. Recommended: add `https://www.babykickcount.com/support` with `hello@babykickcount.com`, basic troubleshooting, privacy, and terms links.
- [x] Update the privacy policy so it matches the native app exactly: SwiftData/UserDefaults, not IndexedDB or "web equivalent local storage." Include data deletion behavior, CSV export behavior, contact path, and any beta email collection if that form becomes real.
- [x] Decide whether the website beta invite form is real. If it collects email, wire it to a real backend/list and update the privacy policy. If not, remove or replace it with a TestFlight public link or mailto.
- [x] Complete and publish App Store Connect App Privacy as "Data Not Collected" for the production app, because health/session data stays on device and is not sent to the developer. Published April 26, 2026.
- [x] Complete age rating questionnaire accurately. Saved April 26, 2026 as `9+` for most regions, with no Made for Kids override, no user-generated content, no unrestricted web access, no gambling, no purchases, no mature media, no medical treatment information, and health/wellness topics marked yes.
- [ ] Declare Regulated Medical Device status in App Store Connect. Current app positioning/disclaimer supports `No`; do not save until confirmed.
- [ ] Fill App Review Information. No demo account is required because there is no login, and reviewer notes are already filled. Contact first name, last name, phone, and email are still blank in App Store Connect.
- [x] Make sure every URL in metadata works in a private browser: website, privacy, support, terms.
- [x] Remove placeholder, temporary, or dev-only content before review: website Tweaks panel, React/Babel development scripts, placeholder app smart banner app ID, and any "coming soon" language in App Store metadata.
- [x] Deploy the updated website and re-check `https://www.babykickcount.com/privacy`, `/terms`, `/support`, and `/llms.txt` in a private browser. Production deployment `babybeats-cnygfx18u-acrobats-projects.vercel.app` is aliased to `www.babykickcount.com`.

## P1: App Store Product Page

- [x] Update App Store Connect product name to `Littletaps - Baby Kick Count` (28 characters, under Apple's 30-character limit). Local app display name is `Littletaps`.
- [x] Pick a subtitle under 30 characters. Saved as `Calm fetal movement tracker`.
- [x] Draft and save the first three lines of the description around what a first-time user sees:

```text
Count your baby's movements with one calm tap.

Littletaps is a private, ad-free fetal movement tracker for the third trimester. Start a session, tap when you feel movement, and see your history over time.
```

- [x] Include a plain medical disclaimer near the end of the description: the app is an informational wellness tool, not a medical device, and users should contact their healthcare provider with concerns.
- [x] Draft and save keywords within Apple's 100-byte limit, avoiding repeated title words:

```text
pregnancy,fetal movement,third trimester,OB,midwife,prenatal,maternity,timer,wellness
```

- [x] Choose primary/secondary categories. Saved as Health & Fitness primary and no secondary category.
- [x] Confirm pricing and availability. Saved April 26, 2026 as free (`$0.00`) with 175 countries/regions available on app release.
- [x] Upload 1-10 screenshots using Apple's current required iPhone sizes. App Store Connect shows `9 of 10 Screenshots` for the 6.5-inch display. Source files are in `app_store_screenshots/iphone_6_7/*` as exact `1284 x 2778` PNGs; keep `app_store_screenshots/iphone_6_9/*` only as the original `1320 x 2868` source set.
- [ ] Capture screenshots from a fresh simulator or device with fictional data only. Suggested set: onboarding, active counter, completed summary, history calendar, settings/export, information disclaimer.
- [ ] Make screenshots match the submitted build exactly. Do not show features that are not in the binary.
- [x] Verify the 1024 x 1024 app icon has no transparency, matches the website branding, and looks good on light/dark App Store surfaces. `sips` reports `1024 x 1024` and `hasAlpha: no`.
- [x] Once App Store Connect generates the Apple app ID, update the website smart banner meta tag with `app-id=6763963304`.

## P1: TestFlight And QA

- [ ] Run internal TestFlight before App Review.
- [ ] Test on at least two physical devices: one small supported device and one large current device.
- [ ] Test fresh install, cold launch, onboarding, first tap, pause, resume, undo, complete at 10 kicks, end early, summary notes/rating, history, delete, settings, sound choices, haptics, keep-screen-awake, and CSV export.
- [ ] Test offline/airplane mode. The app should remain fully usable.
- [ ] Test after force quit and relaunch during an active or paused session.
- [ ] Test with Dynamic Type at very large accessibility sizes.
- [ ] Test with VoiceOver. The primary tap target already has an accessibility label; verify every control is reachable and understandable.
- [ ] Test Increase Contrast and Reduce Motion.
- [ ] Check safe areas on the smallest supported iPhone and a notched/Dynamic Island device.
- [ ] Verify interactive targets are at least 44 x 44 pt or have enough tappable padding.
- [ ] Test CSV exports for comma, quote, and newline escaping in notes.
- [x] Add focused unit tests for `SessionStateMachine` and `ExportService`; these are small and high-value for a health-adjacent app.
- [ ] Consider a debug-only way to test timeout behavior without waiting two hours, then make sure it is removed from release builds.
- [ ] Archive and upload using "App Store Connect," not "TestFlight Internal Only," so the build can be used for App Review and distribution.

## P1: Website Launch Cleanup

- [x] Remove the production Tweaks panel and the `react.development.js`, `react-dom.development.js`, and Babel standalone scripts from `web/index.html`, or gate them behind a local-only/dev flag.
- [x] Align all website privacy copy with the native app. Replace references to IndexedDB/web PWA storage unless a separate web app is intentionally shipping.
- [x] Update `web/llms.txt`: remove "also available as a web PWA" and "IndexedDB" if the shipped product is native iOS only.
- [x] Either self-host fonts/scripts or disclose third-party font/CDN requests in the privacy policy. The app has no trackers, but the website currently requests Google Fonts and unpkg resources.
- [x] Replace beta invite UX with a real TestFlight public link, mailing-list implementation, or simple `mailto:` flow.
- [x] Update sitemap/canonical URLs if `/privacy` and `/terms` are the preferred clean URLs.
- [x] Add `/support` and use it for App Store Connect Support URL.
- [ ] After App Store approval, replace TestFlight CTAs with App Store download CTAs.

## P2: Nice To Have Before Public Launch

- [x] Add a lightweight launch checklist to `README.md` or link this file from it.
- [ ] Add automated screenshot capture scripts for App Store sizes.
- [ ] Add basic UI tests for onboarding, counting, summary, and export availability.
- [ ] Add release notes template for version `1.0`.
- [ ] Consider localization readiness if launching outside English-first regions.
- [ ] Consider legal review of the privacy policy, terms, and medical disclaimer before global release.

## App Review Notes Draft

```text
Littletaps is a native iPhone wellness logging app for counting fetal movements. It does not require an account, does not use a backend, does not collect analytics, does not use HealthKit, and does not include purchases or subscriptions.

To test:
1. Launch the app and complete onboarding.
2. Tap the heart to start a session and record movements.
3. Use pause/resume/undo/end early controls.
4. Reach 10 taps to complete a session and view the summary.
5. Open History to see saved sessions.
6. Open Settings to test sound, haptics, screen-awake preference, information, and CSV export.

The app is an informational wellness tool and is not a medical device. It does not diagnose, treat, or replace professional medical advice. Users are instructed to contact a healthcare provider if fetal movements change, slow down, stop, or if they have concerns.
```

## App Privacy Draft

- Tracking: No.
- Data collected by the developer: None, assuming the app remains fully local.
- Data stored locally: kick timestamps, session metadata, optional notes/strength rating, and app preferences.
- Data linked to user by the developer: None.
- Data sent off device: only user-initiated CSV export through the iOS share sheet, sent wherever the user chooses.
- Required reason API: `UserDefaults`, reason `CA92.1`, for app-only preferences.

## Official Sources Used

- Apple App Review Guidelines: https://developer.apple.com/app-store/review/guidelines
- App privacy details: https://developer.apple.com/app-store/app-privacy-details/
- Manage app privacy: https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy
- Privacy manifests and required reason APIs: https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api
- Required reason API values: https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitype
- Screenshot specifications: https://developer.apple.com/help/app-store-connect/reference/screenshot-specifications
- App information limits: https://developer.apple.com/help/app-store-connect/reference/app-information/app-information
- Product page guidance and keywords: https://developer.apple.com/app-store/product-page
- Age rating setup: https://developer.apple.com/help/app-store-connect/manage-app-information/set-an-app-age-rating
- Submit an app: https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-app
- TestFlight overview: https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview/
- Human Interface Guidelines, layout: https://developer.apple.com/design/human-interface-guidelines/layout
- Human Interface Guidelines, accessibility: https://developer.apple.com/design/human-interface-guidelines/accessibility/
