#!/usr/bin/env bash
# Build release APK after all core achievement badge PNGs exist.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

FORCE=false
SKIP_TESTS=false
for arg in "$@"; do
  case "$arg" in
    --force) FORCE=true ;;
    --skip-tests) SKIP_TESTS=true ;;
    -h|--help)
      echo "Usage: $0 [--force] [--skip-tests]"
      echo "  --force       Build even if core achievement PNGs are incomplete"
      echo "  --skip-tests  Skip flutter test before build"
      exit 0
      ;;
  esac
done

echo "==> Checking core achievement badge assets (110 required)"
if python3 scripts/check_core_achievement_assets.py --json > /tmp/core_assets.json; then
  READY=$(python3 -c "import json; print(json.load(open('/tmp/core_assets.json'))['ready'])")
  echo "    All core assets present ($READY/110)."
else
  python3 scripts/check_core_achievement_assets.py || true
  if [ "$FORCE" != true ]; then
    echo ""
    echo "Aborting release build. Finish the asset queue first:"
    echo "  python3 scripts/image_gen.py status"
    echo "  # Vertiege Asset Generator agent — process pending achievement_badge rows"
    echo "Or pass --force to build anyway (category icon fallbacks)."
    exit 1
  fi
  echo "    --force: continuing without full core badge set."
fi

if [ "$SKIP_TESTS" != true ]; then
  echo "==> flutter test"
  flutter test
fi

if [ ! -f android/key.properties ] && [ ! -f android/upload-keystore.jks ]; then
  echo "==> Warning: android/key.properties missing — APK will use debug signing."
fi

echo "==> flutter build apk --release"
flutter build apk --release --no-tree-shake-icons

APK="$ROOT/build/app/outputs/flutter-apk/app-release.apk"
if [ -f "$APK" ]; then
  ls -lh "$APK"
  echo ""
  echo "Release APK: $APK"
  echo "Install: adb install -r \"$APK\""
else
  echo "APK not found at expected path: $APK" >&2
  exit 1
fi
