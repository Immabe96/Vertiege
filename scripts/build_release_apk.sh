#!/usr/bin/env bash
# Build release APK after all core achievement badge PNGs exist.
# Default: arm64-v8a only (~73MB) — matches modern phones; use --split-per-abi for all CPUs.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
RELEASES="$ROOT/releases"

FORCE=false
SKIP_TESTS=false
SPLIT_PER_ABI=false
BUMP_BUILD=true
for arg in "$@"; do
  case "$arg" in
    --force) FORCE=true ;;
    --skip-tests) SKIP_TESTS=true ;;
    --split-per-abi) SPLIT_PER_ABI=true ;;
    --no-bump) BUMP_BUILD=false ;;
    -h|--help)
      echo "Usage: $0 [--force] [--skip-tests] [--split-per-abi] [--no-bump]"
      echo "  --force         Build even if core achievement PNGs are incomplete"
      echo "  --skip-tests    Skip flutter test before build"
      echo "  --split-per-abi Build armeabi-v7a + arm64 + x86_64 APKs (default is arm64 only)"
      echo "  --no-bump       Do not increment pubspec build number (+N)"
      exit 0
      ;;
  esac
done

bump_pubspec_build() {
  local line name build
  line=$(grep -E '^version:' pubspec.yaml | head -1)
  raw="${line#version: }"
  raw="${raw// /}"
  name="${raw%%+*}"
  build="${raw#*+}"
  build=$((build + 1))
  sed -i '' "s/^version: .*/version: ${name}+${build}/" pubspec.yaml
  echo "Bumped pubspec to ${name}+${build}"
}

if [ "$BUMP_BUILD" = true ]; then
  echo "==> Bump build number in pubspec.yaml"
  bump_pubspec_build
fi

echo "==> Sync lib/config/build_info.dart from pubspec"
chmod +x scripts/sync_app_version.sh
./scripts/sync_app_version.sh

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

# Read version for release artifacts
VERSION_LINE=$(grep -E '^version:' pubspec.yaml | head -1)
RAW="${VERSION_LINE#version: }"
RAW="${RAW// /}"
VNAME="${RAW%%+*}"
VBUILD="${RAW#*+}"
GIT_SHA=$(git rev -q --short HEAD 2>/dev/null || echo "unknown")
STAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
mkdir -p "$RELEASES"

if [ "$SPLIT_PER_ABI" = true ]; then
  echo ""
  echo "Per-ABI APKs:"
  ls -lh "$ROOT/build/app/outputs/flutter-apk/"/*-release.apk 2>/dev/null || true
  for apk in "$ROOT/build/app/outputs/flutter-apk/"/*-release.apk; do
    [ -f "$apk" ] || continue
    base=$(basename "$apk")
    dest="$RELEASES/vertiege-${VNAME}+${VBUILD}-${base}"
    cp "$apk" "$dest"
    echo "Copied: $dest"
  done
else
  SRC="$ROOT/build/app/outputs/flutter-apk/app-release.apk"
  DEST="$RELEASES/vertiege-${VNAME}+${VBUILD}-arm64-release.apk"
  if [ -f "$SRC" ]; then
    cp "$SRC" "$DEST"
    ls -lh "$DEST"
    MANIFEST="$RELEASES/manifest-${VNAME}+${VBUILD}.json"
    cat > "$MANIFEST" <<MANIFEST_EOF
{
  "version": "${VNAME}",
  "build": ${VBUILD},
  "label": "${VNAME}+${VBUILD}",
  "git": "${GIT_SHA}",
  "built_at": "${STAMP}",
  "abi": "arm64-v8a",
  "apk": "$(basename "$DEST")",
  "supabase_project": "wjaphoaxalvgjnrwqjwe"
}
MANIFEST_EOF
    echo ""
    echo "Release APK: $DEST"
    echo "Manifest:    $MANIFEST"
    echo "Install: adb install -r \"$DEST\""
  else
    echo "APK not found at expected path: $SRC" >&2
    exit 1
  fi
fi
