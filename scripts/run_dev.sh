#!/usr/bin/env bash
# Run Vertiege on a connected device or emulator (iOS or Android).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
export PATH="/opt/homebrew/bin:$HOME/development/flutter/bin:$PATH"

PLATFORM=""
DEVICE_ID=""
for arg in "$@"; do
  case "$arg" in
    -d) shift; DEVICE_ID="${1:-}"; shift || true ;;
    ios|android) PLATFORM="$arg" ;;
    -h|--help)
      echo "Usage: $0 [ios|android] [-d DEVICE_ID]"
      echo "  ios      Prefer iOS simulator (default on macOS if no device connected)"
      echo "  android  Prefer Android emulator/device"
      exit 0
      ;;
  esac
done

if [[ ! -f .env ]]; then
  echo "WARN: .env missing — copy .env.template and add Supabase keys" >&2
fi

if [[ -d ios/Pods ]] || [[ -f ios/Podfile.lock ]]; then
  :
else
  echo "==> pod install (first iOS run)"
  (cd ios && pod install)
fi

ARGS=()
if [[ -n "$DEVICE_ID" ]]; then
  ARGS+=(-d "$DEVICE_ID")
fi
if [[ "$PLATFORM" == "ios" ]]; then
  ARGS+=(-d ios)
elif [[ "$PLATFORM" == "android" ]]; then
  ARGS+=(-d android)
fi

echo "==> flutter run ${ARGS[*]:-}"
flutter run "${ARGS[@]}"
