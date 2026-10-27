#!/bin/bash
# Renders the README screenshots from docs/screenshots/mock/notch.html with headless Chrome.
# The scenes use sample data only, so nothing from the machine running this ends up in them.
#
# Usage: scripts/render-readme-mocks.sh
set -euo pipefail

cd "$(dirname "$0")/.."
CHROME="${CHROME:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"
PAGE="file://$(pwd)/docs/screenshots/mock/notch.html"
OUT="docs/screenshots"

render() {
  local scene="$1" size="$2"
  "$CHROME" --headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=2 \
    --window-size="$size" --screenshot="$OUT/$scene.png" "$PAGE#$scene" >/dev/null 2>&1
  echo "$OUT/$scene.png"
}

render home 1180,240
render music 520,70
render weather 520,70
render pomodoro 520,70
