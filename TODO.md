# Apple App Store Launch TODO

Generated on April 26, 2026 after reviewing the native iOS app, the production website, the user-provided App Store submission checklist, and current Apple documentation.

## Current State

- App target: native SwiftUI iPhone app in `ios/`.
- Bundle identifier: `com.babykickcount.app`.
- Display name: `Baby Kick Count`.
- Version/build: `1.0.0` / `1`.
- Deployment target: iOS 17.0.
- Device family: iPhone only.
- Simulator build status: passed with `xcodebuild -project ios/BabyKickCount.xcodeproj -scheme BabyKickCount -destination 'generic/platform=iOS Simulator' build`.
- App data model: SwiftData sessions/events and UserDefaults preferences, all local.
- Network/account/payment review: no network layer, no web view, no login, no analytics SDK, no StoreKit, no Stripe, no ads.
- Website: production is live at `https://www.babykickcount.com`; `/privacy`, `/terms`, `/llms.txt`, and OG image respond successfully.

## P0: Must Finish Before First App Store Submission

- [ ] Create the App Store Connect app record with the exact bundle ID `com.babykickcount.app`, platform iOS, primary language, SKU, and final app name.
- [ ] Set the signing team in Xcode, confirm App Store distribution signing, archive a Release build, upload through Xcode/App Store Connect, and verify the uploaded build appears in App Store Connect.
- [ ] Add `PrivacyInfo.xcprivacy` to the iOS target. The app uses `UserDefaults` in `PreferencesStore.swift`, so declare `NSPrivacyAccessedAPICategoryUserDefaults` with reason `CA92.1` for app-only preferences. Set tracking to false and declare no collected data unless a new network/data feature is added.
- [ ] Add easily accessible in-app links for Privacy Policy, Terms, and Support, likely under Settings -> Information & Help. Apple requires the privacy policy link in App Store Connect metadata and inside the app.
- [ ] Use `https://www.babykickcount.com/privacy` as the App Store Connect Privacy Policy URL because it returns `200` directly. The `.html` URL redirects cleanly, but the clean URL is safer.
- [ ] Create or designate a Support URL that includes real contact information. Recommended: add `https://www.babykickcount.com/support` with `hello@babykickcount.com`, basic troubleshooting, privacy, and terms links.
- [ ] Update the privacy policy so it matches the native app exactly: SwiftData/UserDefaults, not IndexedDB or "web equivalent local storage." Include data deletion behavior, CSV export behavior, contact path, and any beta email collection if that form becomes real.
- [ ] Decide whether the website beta invite form is real. If it collects email, wire it to a real backend/list and update the privacy policy. If not, remove or replace it with a TestFlight public link or mailto.
- [ ] Complete App Store Connect App Privacy. Current draft answer: "Data Not Collected" for the production app, because health/session data stays on device and is not sent to the developer. Revisit this if email signup, analytics, crash reporting, server sync, HealthKit, or support intake moves into the app.
- [ ] Complete age rating questionnaire accurately. Do not mark the app as Made for Kids. Declare no user-generated content, unrestricted web access, gambling, purchases, or mature media unless features change.
- [ ] Fill App Review Information. No demo account is required because there is no login, but include reviewer notes explaining how to test the core flow.
- [ ] Make sure every URL in metadata works in a private browser: website, privacy, support, terms.
- [ ] Remove placeholder, temporary, or dev-only content before review: website Tweaks panel, React/Babel development scripts, placeholder app smart banner app ID, and any "coming soon" language in App Store metadata.

## P1: App Store Product Page

- [ ] Final app name: `Baby Kick Count` (under Apple's 30-character limit).
- [ ] Pick a subtitle under 30 characters. Candidate: `Calm fetal movement tracker`.
- [ ] Draft the first three lines of the description around what a first-time user sees:

```text
Count your baby's movements with one calm tap.

Baby Kick Count is a private, ad-free fetal movement tracker for the third trimester. Start a session, tap when you feel movement, and see your history over time.
```

- [ ] Include a plain medical disclaimer near the end of the description: the app is an informational wellness tool, not a medical device, and users should contact their healthcare provider with concerns.
- [ ] Draft keywords within Apple's 100-byte limit, avoiding repeated title words. Candidate:

```text
pregnancy,fetal movement,third trimester,OB,midwife,prenatal,maternity,timer,wellness
```

- [ ] Choose primary/secondary categories. Recommended starting point: Health & Fitness primary; consider Medical only if you want the store positioning to invite stricter health review.
- [ ] Confirm pricing and availability. Current product promise says free/ad-free; make sure the App Store price matches.
- [ ] Upload 1-10 screenshots using Apple's current required iPhone sizes. Current `website_images/*` are `1206 x 2622` and are useful source material, but should not be treated as the final required App Store screenshot set.
- [ ] Capture screenshots from a fresh simulator or device with fictional data only. Suggested set: onboarding, active counter, completed summary, history calendar, settings/export, information disclaimer.
- [ ] Make screenshots match the submitted build exactly. Do not show features that are not in the binary.
- [ ] Verify the 1024 x 1024 app icon has no transparency, matches the website branding, and looks good on light/dark App Store surfaces.
- [ ] Once App Store Connect generates the Apple app ID, update the website smart banner meta tag with `app-id=...`.

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
- [ ] Add focused unit tests for `SessionStateMachine` and `ExportService`; these are small and high-value for a health-adjacent app.
- [ ] Consider a debug-only way to test timeout behavior without waiting two hours, then make sure it is removed from release builds.
- [ ] Archive and upload using "App Store Connect," not "TestFlight Internal Only," so the build can be used for App Review and distribution.

## P1: Website Launch Cleanup

- [ ] Remove the production Tweaks panel and the `react.development.js`, `react-dom.development.js`, and Babel standalone scripts from `web/index.html`, or gate them behind a local-only/dev flag.
- [ ] Align all website privacy copy with the native app. Replace references to IndexedDB/web PWA storage unless a separate web app is intentionally shipping.
- [ ] Update `web/llms.txt`: remove "also available as a web PWA" and "IndexedDB" if the shipped product is native iOS only.
- [ ] Either self-host fonts/scripts or disclose third-party font/CDN requests in the privacy policy. The app has no trackers, but the website currently requests Google Fonts and unpkg resources.
- [ ] Replace beta invite UX with a real TestFlight public link, mailing-list implementation, or simple `mailto:` flow.
- [ ] Update sitemap/canonical URLs if `/privacy` and `/terms` are the preferred clean URLs.
- [ ] Add `/support` and use it for App Store Connect Support URL.
- [ ] After App Store approval, replace TestFlight CTAs with App Store download CTAs.

## P2: Nice To Have Before Public Launch

- [ ] Add a lightweight launch checklist to `README.md` or link this file from it.
- [ ] Add automated screenshot capture scripts for App Store sizes.
- [ ] Add basic UI tests for onboarding, counting, summary, and export availability.
- [ ] Add release notes template for version `1.0`.
- [ ] Consider localization readiness if launching outside English-first regions.
- [ ] Consider legal review of the privacy policy, terms, and medical disclaimer before global release.

## App Review Notes Draft

```text
Baby Kick Count is a native iPhone wellness logging app for counting fetal movements. It does not require an account, does not use a backend, does not collect analytics, does not use HealthKit, and does not include purchases or subscriptions.

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
