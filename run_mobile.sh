#!/bin/bash
# Runs the Flutter app on a physical Android device wired over USB.
# Uses `adb reverse` to tunnel port 3000 through USB — no Wi-Fi required.
#
# Usage:
#   ./run_mobile.sh            # debug mode
#   ./run_mobile.sh --release  # release mode (no hot-reload)
#
# Prerequisites:
#   1. Next.js server running:  cd web && npm run dev
#   2. Phone connected via USB with USB debugging enabled

set -e

# Tunnel the Next.js port through the USB cable so the phone can reach
# localhost:3000 on this machine — bypasses Wi-Fi/AP-isolation entirely.
ADB="${ANDROID_HOME:-$HOME/Android/Sdk}/platform-tools/adb"
echo "Setting up adb reverse for port 3000..."
"$ADB" reverse tcp:3000 tcp:3000

API_URL="http://localhost:3000/api/v1"
echo "Using API_BASE_URL=$API_URL"
echo ""

cd "$(dirname "$0")/mobile"
flutter run \
  --dart-define=API_BASE_URL="$API_URL" \
  "$@"
