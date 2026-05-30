#!/usr/bin/env bash
# Build signed App Bundle (.aab) for Google Play closed / open testing.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

BUMP_BUILD=true
SKIP_TESTS=false
for arg in "$@"; do
  case "$arg" in
    --no-bump) BUMP_BUILD=false ;;
    --skip-tests) SKIP_TESTS=true ;;
    -h|--help)
      echo "Usage: $0 [--no-bump] [--skip-tests]"
      exit 0
      ;;
  esac
done

if [ "$BUMP_BUILD" = true ]; then
  line=$(grep -E '^version:' pubspec.yaml | head -1)
  raw="${line#version: }"
  raw="${raw// /}"
  name="${raw%%+*}"
  build="${raw#*+}"
  build=$((build + 1))
  sed -i '' "s/^version: .*/version: ${name}+${build}/" pubspec.yaml
  echo "Bumped pubspec to ${name}+${build}"
fi

chmod +x scripts/sync_app_version.sh
./scripts/sync_app_version.sh

if [ "$SKIP_TESTS" != true ]; then
  echo "==> flutter test"
  flutter test
fi

if [ ! -f android/key.properties ]; then
  echo "ERROR: android/key.properties missing. Run ./scripts/setup-android-signing.sh" >&2
  exit 1
fi

echo "==> flutter build appbundle --release"
flutter build appbundle --release --no-tree-shake-icons

OUT="$ROOT/build/app/outputs/bundle/release/app-release.aab"
if [ ! -f "$OUT" ]; then
  echo "AAB not found at $OUT" >&2
  exit 1
fi

VERSION_LINE=$(grep -E '^version:' pubspec.yaml | head -1)
RAW="${VERSION_LINE#version: }"
RAW="${RAW// /}"
VNAME="${RAW%%+*}"
VBUILD="${RAW#*+}"
DEST="$ROOT/releases/vertiege-${VNAME}+${VBUILD}-release.aab"
mkdir -p "$ROOT/releases"
cp "$OUT" "$DEST"
ls -lh "$DEST"
echo ""
echo "Upload to Play Console → Testing → Closed testing:"
echo "  $DEST"
