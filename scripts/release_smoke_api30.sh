#!/usr/bin/env bash
# Build a release APK and print API-level smoke steps for Android 11 (API 30).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "== Vertiege API 30 release smoke =="
echo "Building release APK (arm64)..."
flutter build apk --release --target-platform android-arm64

APK="$ROOT/build/app/outputs/flutter-apk/app-release.apk"
if [[ ! -f "$APK" ]]; then
  echo "APK not found at $APK" >&2
  exit 1
fi

MIN_SDK="$(grep -E '^flutter\.minSdkVersion=' android/local.properties 2>/dev/null | cut -d= -f2- || true)"
TARGET_SDK="$(grep -E '^flutter\.targetSdkVersion=' android/local.properties 2>/dev/null | cut -d= -f2- || true)"

echo ""
echo "flutter.minSdkVersion=${MIN_SDK:-<from Flutter SDK>}"
echo "flutter.targetSdkVersion=${TARGET_SDK:-<from Flutter SDK>}"
echo "APK: $APK"
echo ""
echo "On an API 30 (Android 11) device or emulator:"
echo "  adb install -r \"$APK\""
echo "  1. Cold start → sign in"
echo "  2. Open invite deep link (logged out) → sign up → land in invited world"
echo "  3. World feed + voice channel join/leave"
echo "  4. Subscription purchase or restore (sandbox account)"
echo ""
echo "See docs/operations/uat/api30-release-smoke.md"
