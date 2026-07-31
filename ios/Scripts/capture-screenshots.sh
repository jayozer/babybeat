#!/usr/bin/env bash
#
# Regenerates the App Store product-page screenshots.
#
# Apple requires the screenshots to match the submitted binary, so run this
# after any visual change and re-upload the results. It drives the app with
# ScreenshotCaptureTests rather than capturing by hand, so the set stays
# reproducible and every shot lands on a settled screen.
#
# Each size gets its own throwaway simulator, erased first so onboarding
# appears and so no real session data leaks into the screenshots. The
# simulators you already have booted are left alone.
#
# Usage: ios/Scripts/capture-screenshots.sh [--keep-simulators]

set -euo pipefail

cd "$(dirname "$0")/.."

PROJECT="BabyKickCount.xcodeproj"
SCHEME="BabyKickCount"
RUNNER_ID="com.babykickcount.app.uitests.xctrunner"
DERIVED="/tmp/babybeat-screenshots-derived"
KEEP_SIMULATORS=0

[[ "${1:-}" == "--keep-simulators" ]] && KEEP_SIMULATORS=1

# slot | device type | simulator name | expected width | expected height
SLOTS=(
  "iphone_6_9|iPhone 17 Pro Max|Littletaps Shots 6.9|1320|2868"
  "iphone_6_7|iPhone 14 Plus|Littletaps Shots 6.7|1284|2778"
)

fail() { printf '\033[31m✗ %s\033[0m\n' "$1" >&2; exit 1; }
step() { printf '\n\033[1m▸ %s\033[0m\n' "$1"; }
ok()   { printf '\033[32m  ✓ %s\033[0m\n' "$1"; }

command -v xcodegen >/dev/null || fail "xcodegen not found — brew install xcodegen"

step "Regenerating the Xcode project"
xcodegen generate >/dev/null
ok "project up to date"

for entry in "${SLOTS[@]}"; do
  IFS='|' read -r slot device_type sim_name want_w want_h <<< "$entry"

  step "$slot — ${want_w}x${want_h} on $device_type"

  # Reuse the named simulator across runs so repeated captures stay cheap.
  udid=$(xcrun simctl list devices -j \
    | python3 -c "
import json,sys
name=sys.argv[1]
for runtime, devices in json.load(sys.stdin)['devices'].items():
    for d in devices:
        if d['name'] == name:
            print(d['udid']); break
" "$sim_name" || true)

  if [[ -z "$udid" ]]; then
    udid=$(xcrun simctl create "$sim_name" "$device_type")
    ok "created simulator $udid"
  else
    ok "reusing simulator $udid"
  fi

  # Erase so the app installs fresh: onboarding only shows on first launch,
  # and this keeps any real session data out of the product page.
  xcrun simctl shutdown "$udid" 2>/dev/null || true
  xcrun simctl erase "$udid"
  xcrun simctl boot "$udid"
  xcrun simctl bootstatus "$udid" -b >/dev/null
  ok "booted clean"

  # Apple's own marketing convention, and it removes the wandering clock and
  # partial signal bars that made the previous set look inconsistent.
  xcrun simctl status_bar "$udid" override \
    --time "9:41" \
    --dataNetwork wifi \
    --wifiMode active --wifiBars 3 \
    --cellularMode active --cellularBars 4 \
    --operatorName "" \
    --batteryState discharging --batteryLevel 100
  ok "status bar pinned to 9:41"

  step "  Driving the app"
  log="/tmp/babybeat-screenshots-$slot.log"
  TEST_RUNNER_CAPTURE_SCREENSHOTS=1 xcodebuild \
      -project "$PROJECT" \
      -scheme "$SCHEME" \
      -destination "id=$udid" \
      -derivedDataPath "$DERIVED" \
      -only-testing:BabyKickCountUITests/ScreenshotCaptureTests \
      test > "$log" 2>&1 &
  build_pid=$!

  # On a simulator booted headlessly, xcodebuild reliably goes to sleep after
  # the tests finish and never exits — 0% CPU, no further output, the run just
  # sits there. The screenshots are written to disk during the run, so wait for
  # the result line to appear and then reap the process rather than hanging.
  waited=0
  while kill -0 "$build_pid" 2>/dev/null; do
    # Must match the completion line, not "... started" — matching the start
    # kills the run five seconds in.
    if grep -qE "Test Suite 'Selected tests' (passed|failed)" "$log" 2>/dev/null; then
      sleep 5   # let it finish flushing the log
      kill "$build_pid" 2>/dev/null || true
      break
    fi
    if (( waited >= 900 )); then
      kill "$build_pid" 2>/dev/null || true
      fail "capture timed out for $slot — see $log"
    fi
    sleep 5
    waited=$((waited + 5))
  done
  wait "$build_pid" 2>/dev/null || true

  grep -q "Test Suite 'Selected tests' passed" "$log" \
    || fail "capture failed for $slot — see $log"
  ok "capture run finished"

  container=$(xcrun simctl get_app_container "$udid" "$RUNNER_ID" data)
  source_dir="$container/Documents/AppStoreScreenshots"
  [[ -d "$source_dir" ]] || fail "no screenshots written for $slot"

  out_dir="../app_store_screenshots/$slot"
  mkdir -p "$out_dir"
  rm -f "$out_dir"/*.png
  cp "$source_dir"/*.png "$out_dir/"

  step "  Verifying $slot"
  count=0
  for png in "$out_dir"/*.png; do
    w=$(sips -g pixelWidth  "$png" | awk '/pixelWidth/  {print $2}')
    h=$(sips -g pixelHeight "$png" | awk '/pixelHeight/ {print $2}')
    [[ "$w" == "$want_w" && "$h" == "$want_h" ]] \
      || fail "$(basename "$png") is ${w}x${h}, expected ${want_w}x${want_h}"
    count=$((count + 1))
  done
  [[ "$count" -eq 9 ]] || fail "expected 9 screenshots for $slot, got $count"
  ok "$count screenshots at ${want_w}x${want_h}"

  if [[ "$KEEP_SIMULATORS" -eq 0 ]]; then
    xcrun simctl shutdown "$udid" >/dev/null 2>&1 || true
    xcrun simctl delete "$udid" >/dev/null 2>&1 || true
  fi
done

printf '\n\033[32m✓ Screenshots regenerated.\033[0m\n'
cat <<'EOF'

Next: upload app_store_screenshots/iphone_6_9/* to the 6.9-inch slot in
App Store Connect. That is the required iPhone size. The 6.7 set fits the
6.5-inch slot, which is optional — leave it or replace the existing upload,
but do not leave a stale set in a slot the submitted build no longer matches.
EOF
