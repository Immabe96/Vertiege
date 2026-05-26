#!/usr/bin/env bash
# Build release APK after all core achievement badge PNGs exist.
# Default: arm64-v8a only (~73MB) — matches modern phones; use --split-per-abi for all CPUs.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

FORCE=false
SKIP_TESTS=false
SPLIT_PER_ABI=false
for arg in "$@"; do
  case "$arg" in
    --force) FORCE=true ;;
    --skip-tests) SKIP_TESTS=true ;;
    --split-per-abi) SPLIT_PER_ABI=true ;;
    -h|--help)
      echo "Usage: $0 [--force] [--skip-tests] [--split-per-abi]"
      echo "  --force         Build even if core achievement PNGs are incomplete"
      echo "  --skip-tests    Skip flutter test before build"
      echo "  --split-per-abi Build armeabi-v7a + arm64 + x86_64 APKs (default is arm64 only)"
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

BUILD_FLAGS=(--release --no-tree-shake-icons)
if [ "$SPLIT_PER_ABI" = true ]; then
  BUILD_FLAGS+=(--split-per-abi)
  echo "==> Building per-CPU APKs (armeabi-v7a, arm64-v8a, x86_64)"
else
  BUILD_FLAGS+=(--target-platform android-arm64)
  echo "==> Building arm64-v8a release APK only"
fi

echo "==> flutter build apk ${BUILD_FLAGS[*]}"
flutter build apk "${BUILD_FLAGS[@]}"

if [ "$SPLIT_PER_ABI" = true ]; then
  echo ""
  echo "Per-ABI APKs:"
  ls -lh "$ROOT/build/app/outputs/flutter-apk/"/*-release.apk 2>/dev/null || true
  echo "Install (arm64): adb install -r build/app/outputs/flutter-apk/app-arm64-v8a-release.apk"
else
  APK="$ROOT/build/app/outputs/flutter-apk/app-release.apk"
  if [ -f "$APK" ]; then
    ls -lh "$APK"
    echo ""
    echo "Release APK (arm64-v8a): $APK"
    echo "Install: adb install -r \"$APK\""
  else
    echo "APK not found at expected path: $APK" >&2
    exit 1
  fi
fi
