#!/bin/bash
# Runs the Flutter app on a physical Android device wired over USB.
# Automatically detects your machine's local IP so the phone can reach
# the Next.js dev server running on this machine.
#
# Usage:
#   ./run_mobile.sh            # debug mode
#   ./run_mobile.sh --release  # release mode (no hot-reload)
#
# Prerequisites:
#   1. Next.js server running:  cd web && npm run dev
#   2. Phone connected via USB with USB debugging enabled
#   3. Both phone and machine on the same Wi-Fi network

set -e

# Pick the first non-loopback IPv4 on a local subnet (192.168.x.x or 10.x.x.x)
LOCAL_IP=$(ip addr show | grep "inet " | grep -v "127.0.0.1" | grep -oP '(?<=inet )\d+\.\d+\.\d+\.\d+' | grep -E "^(192\.168\.|10\.)" | head -1)

if [ -z "$LOCAL_IP" ]; then
  echo "ERROR: Could not detect a local network IP."
  echo "Set it manually: flutter run --dart-define=API_BASE_URL=http://YOUR_IP:3000/api/v1"
  exit 1
fi

API_URL="http://$LOCAL_IP:3000/api/v1"
echo "Using API_BASE_URL=$API_URL"
echo ""

cd "$(dirname "$0")/mobile"
flutter run \
  --dart-define=API_BASE_URL="$API_URL" \
  "$@"
