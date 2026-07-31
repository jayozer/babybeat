#!/usr/bin/env bash
#
# Renders og-cover.html to web/images/og-cover.png at the 1200x630 Open Graph
# size — the card that appears whenever the site is shared.
#
# The source lives here rather than under web/ because everything in web/ is
# deployed verbatim, and with vercel.json's cleanUrls the HTML would become a
# live page at /images/og-cover.
#
# Regenerate after any copy or branding change: the card read "Baby Kick Count"
# long after the app was renamed Littletaps.

set -euo pipefail
cd "$(dirname "$0")"

OUT="$PWD/../../web/images/og-cover.png"
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
[[ -x "$CHROME" ]] || { echo "Google Chrome not found at $CHROME" >&2; exit 1; }

# --virtual-time-budget gives the webfonts time to load before the capture;
# without it the card renders in the fallback serif.
"$CHROME" \
  --headless \
  --disable-gpu \
  --hide-scrollbars \
  --force-device-scale-factor=1 \
  --window-size=1200,630 \
  --virtual-time-budget=10000 \
  --screenshot="$OUT" \
  "file://$PWD/og-cover.html" 2>/dev/null

w=$(sips -g pixelWidth  "$OUT" | awk '/pixelWidth/{print $2}')
h=$(sips -g pixelHeight "$OUT" | awk '/pixelHeight/{print $2}')
[[ "$w" == "1200" && "$h" == "630" ]] \
  || { echo "og-cover.png is ${w}x${h}, expected 1200x630" >&2; exit 1; }

echo "✓ web/images/og-cover.png regenerated at ${w}x${h}"
