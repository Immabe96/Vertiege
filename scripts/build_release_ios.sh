#!/usr/bin/env bash
# Build release IPA for TestFlight (mirrors build_release_appbundle.sh flow).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
export PATH="/opt/homebrew/bin:$HOME/development/flutter/bin:$PATH"

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

if [[ -z "${DEVELOPMENT_TEAM:-}" ]]; then
  if grep -q '^DEVELOPMENT_TEAM = [A-Z0-9]' ios/Flutter/Release.xcconfig 2>/dev/null; then
    DEVELOPMENT_TEAM="$(grep '^DEVELOPMENT_TEAM' ios/Flutter/Release.xcconfig | sed 's/.*= *//;s/ *$//')"
    export DEVELOPMENT_TEAM
  fi
fi

if [[ -z "${DEVELOPMENT_TEAM:-}" ]]; then
  echo "ERROR: Set DEVELOPMENT_TEAM in ios/Flutter/Release.xcconfig" >&2
  exit 1
fi

echo "==> pod install"
(cd ios && pod install)

echo "==> flutter build ipa --release"
flutter build ipa --release --no-tree-shake-icons

IPA="$(find build/ios/ipa -name '*.ipa' 2>/dev/null | head -1)"
if [[ -z "$IPA" ]]; then
  echo "IPA not found under build/ios/ipa" >&2
  exit 1
fi

VERSION_LINE=$(grep -E '^version:' pubspec.yaml | head -1)
RAW="${VERSION_LINE#version: }"
RAW="${RAW// /}"
VNAME="${RAW%%+*}"
VBUILD="${RAW#*+}"
DEST="$ROOT/releases/vertiege-${VNAME}+${VBUILD}-release.ipa"
mkdir -p "$ROOT/releases"
cp "$IPA" "$DEST"
ls -lh "$DEST"
echo ""
echo "Upload with Transporter or Xcode Organizer → Distribute App:"
echo "  $DEST"
