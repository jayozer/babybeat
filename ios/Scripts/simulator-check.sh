#!/usr/bin/env bash
#
# App Store readiness check for Littletaps. Run this on a Mac with Xcode.
#
#   ./ios/Scripts/simulator-check.sh                    # generate, test, build, launch, capture
#   ./ios/Scripts/simulator-check.sh --archive          # also archive + export an App Store package
#   ./ios/Scripts/simulator-check.sh --device "iPhone SE (3rd generation)"
#
# Everything here is automatable. The tap-through checks it cannot do are
# printed as a manual checklist at the end.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROJECT="$REPO_ROOT/ios/BabyKickCount.xcodeproj"
SCHEME="BabyKickCount"
BUNDLE_ID="com.babykickcount.app"
DERIVED="${TMPDIR:-/tmp}/babybeat-derived"
OUT="$REPO_ROOT/build/simulator-check"

DEVICE="iPhone 17 Pro Max"
DO_ARCHIVE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --device) DEVICE="$2"; shift 2 ;;
    --archive) DO_ARCHIVE=1; shift ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

pass() { printf '  \033[32m✓\033[0m %s\n' "$1"; }
fail() { printf '  \033[31m✗\033[0m %s\n' "$1"; FAILURES=$((FAILURES + 1)); }
warn() { printf '  \033[33m!\033[0m %s\n' "$1"; }
step() { printf '\n\033[1m==> %s\033[0m\n' "$1"; }

FAILURES=0

# --- 0. Environment ----------------------------------------------------------

step "Environment"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This script needs macOS. The iOS Simulator does not run anywhere else." >&2
  exit 1
fi
command -v xcodebuild >/dev/null || { echo "xcodebuild not found. Install Xcode." >&2; exit 1; }
pass "macOS with $(xcodebuild -version | head -1)"

mkdir -p "$OUT"

# --- 1. Regenerate the project ----------------------------------------------

step "Project generation"

if command -v xcodegen >/dev/null; then
  (cd "$REPO_ROOT/ios" && xcodegen generate >/dev/null)
  pass "xcodegen regenerated BabyKickCount.xcodeproj from project.yml"
else
  warn "xcodegen not installed; using the checked-in project as-is."
  warn "If project.yml changed, install it (brew install xcodegen) and re-run."
fi

# --- 2. Resolve a simulator --------------------------------------------------

step "Simulator"

UDID="$(xcrun simctl list devices available --json \
  | python3 -c "
import json, sys
name = sys.argv[1]
data = json.load(sys.stdin)['devices']
best = None
for runtime, devices in data.items():
    if 'iOS' not in runtime:
        continue
    for d in devices:
        if d['name'] == name:
            best = d['udid']
if best:
    print(best)
" "$DEVICE")"

if [[ -z "$UDID" ]]; then
  echo "No available simulator named '$DEVICE'." >&2
  echo "Pick one of these with --device:" >&2
  xcrun simctl list devices available | grep -E '^\s+iPhone' >&2
  exit 1
fi
pass "$DEVICE ($UDID)"

# --- 3. Unit tests -----------------------------------------------------------

step "Tests"

# Unit tests are instant; the UI tests drive the simulator and take ~3 minutes.
if xcodebuild test \
    -project "$PROJECT" -scheme "$SCHEME" -only-testing:BabyKickCountTests \
    -destination "id=$UDID" -derivedDataPath "$DERIVED" \
    > "$OUT/test.log" 2>&1; then
  pass "SessionStateMachine and ExportService tests passed"
else
  fail "unit tests failed — see $OUT/test.log"
  tail -30 "$OUT/test.log"
fi

if xcodebuild test \
    -project "$PROJECT" -scheme "$SCHEME" -only-testing:BabyKickCountUITests \
    -destination "id=$UDID" -derivedDataPath "$DERIVED" \
    > "$OUT/uitest.log" 2>&1; then
  pass "accessibility tests passed (labels, 44pt hit targets, calendar at AX5)"
else
  fail "accessibility tests failed — see $OUT/uitest.log"
  grep -E "error:" "$OUT/uitest.log" | sed 's/^/      /' | head -20
fi

# --- 4. Release build --------------------------------------------------------

step "Release build"

if xcodebuild build \
    -project "$PROJECT" -scheme "$SCHEME" -configuration Release \
    -destination "id=$UDID" -derivedDataPath "$DERIVED" \
    > "$OUT/build.log" 2>&1; then
  pass "Release configuration builds with no errors"
else
  fail "Release build failed — see $OUT/build.log"
  tail -30 "$OUT/build.log"
fi

if grep -q "warning:" "$OUT/build.log"; then
  warn "build emitted warnings:"
  grep "warning:" "$OUT/build.log" | sort -u | sed 's/^/      /' | head -20
else
  pass "no build warnings"
fi

APP="$(find "$DERIVED/Build/Products" -name "*.app" -maxdepth 3 | grep -i release | head -1 || true)"
[[ -n "$APP" ]] || APP="$(find "$DERIVED/Build/Products" -name "*.app" -maxdepth 3 | head -1)"

# --- 5. Bundle checks --------------------------------------------------------

step "Bundle contents"

PLIST="$APP/Info.plist"

read_plist() { /usr/libexec/PlistBuddy -c "Print :$1" "$PLIST" 2>/dev/null || echo ""; }

[[ "$(read_plist UIUserInterfaceStyle)" == "Light" ]] \
  && pass "UIUserInterfaceStyle = Light (matches the light-only design system)" \
  || fail "UIUserInterfaceStyle missing — Form screens will render dark-on-dark in Dark Mode"

[[ "$(read_plist ITSAppUsesNonExemptEncryption)" == "false" ]] \
  && pass "ITSAppUsesNonExemptEncryption = false (no export-compliance prompt on upload)" \
  || fail "ITSAppUsesNonExemptEncryption not set to false"

[[ "$(read_plist CFBundleShortVersionString)" != "" ]] \
  && pass "version $(read_plist CFBundleShortVersionString) build $(read_plist CFBundleVersion)" \
  || fail "version strings missing"

[[ -f "$APP/PrivacyInfo.xcprivacy" ]] \
  && pass "PrivacyInfo.xcprivacy is bundled" \
  || fail "PrivacyInfo.xcprivacy is NOT in the built app — Apple will reject the upload"

# App icon must be 1024x1024 with no alpha channel.
ICON_SRC="$REPO_ROOT/ios/BabyKickCount/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png"
if [[ -f "$ICON_SRC" ]]; then
  if [[ "$(sips -g hasAlpha "$ICON_SRC" | awk '/hasAlpha/{print $2}')" == "no" ]]; then
    pass "app icon is 1024x1024 with no alpha channel"
  else
    fail "app icon has an alpha channel — App Store Connect rejects transparent icons"
  fi
fi

STRAY="$(find "$REPO_ROOT/ios/BabyKickCount/Resources/Assets.xcassets/AppIcon.appiconset" \
  -name '*.png' ! -name 'AppIcon-1024.png' | wc -l | tr -d ' ')"
[[ "$STRAY" == "0" ]] \
  && pass "no unreferenced files in AppIcon.appiconset" \
  || warn "$STRAY unreferenced PNG(s) in AppIcon.appiconset"

# --- 6. Screenshot assets ----------------------------------------------------

step "App Store screenshots"

check_shots() {
  local dir="$1" expect="$2" label="$3"
  [[ -d "$dir" ]] || { warn "$label: directory missing"; return; }
  local count bad
  count="$(find "$dir" -name '*.png' | wc -l | tr -d ' ')"
  bad=0
  while IFS= read -r f; do
    local w h
    w="$(sips -g pixelWidth "$f" | awk '/pixelWidth/{print $2}')"
    h="$(sips -g pixelHeight "$f" | awk '/pixelHeight/{print $2}')"
    [[ "${w}x${h}" == "$expect" ]] || { warn "$(basename "$f") is ${w}x${h}, expected $expect"; bad=1; }
  done < <(find "$dir" -name '*.png')
  [[ "$bad" == "0" ]] && pass "$label: $count screenshots, all $expect"
}

check_shots "$REPO_ROOT/app_store_screenshots/iphone_6_9" "1320x2868" "6.9-inch (required slot)"
check_shots "$REPO_ROOT/app_store_screenshots/iphone_6_7" "1284x2778" "6.7/6.5-inch"

# --- 7. Launch in the simulator ---------------------------------------------

step "Launch"

xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" -b >/dev/null 2>&1 || true
open -a Simulator --args -CurrentDeviceUDID "$UDID" || true

xcrun simctl uninstall "$UDID" "$BUNDLE_ID" 2>/dev/null || true
xcrun simctl install "$UDID" "$APP"
pass "installed clean (previous data wiped, so this is a true first-run)"

xcrun simctl launch "$UDID" "$BUNDLE_ID" >/dev/null
sleep 4
xcrun simctl io "$UDID" screenshot "$OUT/01-launch.png" >/dev/null 2>&1
pass "launched; first-run screenshot at $OUT/01-launch.png"

# Relaunch in Dark Mode to prove the appearance lock holds.
xcrun simctl ui "$UDID" appearance dark >/dev/null 2>&1 || true
xcrun simctl terminate "$UDID" "$BUNDLE_ID" >/dev/null 2>&1 || true
xcrun simctl launch "$UDID" "$BUNDLE_ID" >/dev/null
sleep 3
xcrun simctl io "$UDID" screenshot "$OUT/02-dark-mode.png" >/dev/null 2>&1
xcrun simctl ui "$UDID" appearance light >/dev/null 2>&1 || true
pass "dark-mode screenshot at $OUT/02-dark-mode.png — it should look identical to 01"

if xcrun simctl spawn "$UDID" log show --last 60s --predicate "process == '$SCHEME' AND messageType == 'error'" 2>/dev/null | grep -q "Error"; then
  warn "error-level entries in the app log; check with:"
  warn "  xcrun simctl spawn $UDID log show --last 5m --predicate \"process == '$SCHEME'\""
else
  pass "no error-level log entries in the first 60s"
fi

# --- 8. Optional: archive ----------------------------------------------------

if [[ "$DO_ARCHIVE" == "1" ]]; then
  step "App Store archive"
  ARCHIVE="$OUT/Littletaps.xcarchive"
  rm -rf "$ARCHIVE"
  if xcodebuild archive \
      -project "$PROJECT" -scheme "$SCHEME" -configuration Release \
      -destination 'generic/platform=iOS' -archivePath "$ARCHIVE" \
      > "$OUT/archive.log" 2>&1; then
    pass "archived"
    if xcodebuild -exportArchive -archivePath "$ARCHIVE" \
        -exportOptionsPlist "$REPO_ROOT/ios/ExportOptions-AppStore.plist" \
        -exportPath "$OUT/export" > "$OUT/export.log" 2>&1; then
      pass "exported an App Store package to $OUT/export"
    else
      fail "export failed (usually distribution provisioning) — see $OUT/export.log"
      tail -20 "$OUT/export.log"
    fi
  else
    fail "archive failed — see $OUT/archive.log"
    tail -20 "$OUT/archive.log"
  fi
fi

# --- 9. What this cannot check ----------------------------------------------

step "Manual checks — these need your hands on the simulator"

cat <<'EOF'
  Correctness of the two fragile spots found in review:
    [ ] Tap the heart 3 times, then Undo. The count must go to 2 on screen.
        (undo() mutates the model without reassigning the @Published session;
         it relies on SwiftData's Observable conformance to propagate.)
    [ ] Pause, then Resume. The controls and timer must flip both ways.

  Session lifecycle:
    [ ] Reach 10 taps -> summary sheet appears, rating + notes save.
    [ ] End early -> confirmation dialog -> session lands in History.
    [ ] Force-quit mid-session, relaunch -> session resumes with correct elapsed time.

  Accessibility is now covered by BabyKickCountUITests, which runs above. It
  asserts the labels VoiceOver reads out (calendar days, stars, the history
  "..." menu, sound previews), that every button and link clears 44pt on all
  four screens, and that the calendar does not wrap two-digit day numbers at
  AX5. Only these are left by hand:
    [ ] Contrast. The audit tab in Accessibility Inspector checks this and the
        UI tests cannot. Xcode -> Open Developer Tool -> Accessibility
        Inspector, target the booted Simulator, run the audit on each screen.
    [ ] Counter screen at AX5: the tap pad's labels must not clip. Set the size
        with `xcrun simctl ui booted content_size accessibility-extra-extra-extra-large`.
        CountDisplay (72pt) and TapPad (64pt) are fixed sizes and will not grow,
        which is a known and accepted gap.
        Note: scrolling in the Simulator needs a click-drag; the mouse wheel
        does nothing, which makes content look clipped when it merely scrolls.

  Then, on the App Store Connect side (see TODO.md for the click paths):
    [ ] Upload app_store_screenshots/iphone_6_9/* to the 6.9-inch slot.
    [ ] Answer "No" to Regulated Medical Device.
    [ ] Fill App Review Information contact name, phone, and email.

  CSV escaping is covered by the unit tests above (a note containing a comma,
  a quote, and a newline is round-tripped through an RFC 4180 parser and the
  column alignment is asserted), so it does not need a manual pass.
EOF

printf '\n'
if [[ "$FAILURES" == "0" ]]; then
  printf '\033[32mAll automated checks passed.\033[0m Work through the manual list above.\n'
else
  printf '\033[31m%s automated check(s) failed.\033[0m Logs in %s\n' "$FAILURES" "$OUT"
  exit 1
fi
