#!/usr/bin/env bash
# Bump version once, sync build_info.dart, then build Play AAB + TestFlight IPA.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

BUILD_AAB=true
BUILD_IPA=true
SKIP_TESTS=false
BUMP_BUILD=true

for arg in "$@"; do
  case "$arg" in
    --android-only) BUILD_IPA=false ;;
    --ios-only) BUILD_AAB=false ;;
    --skip-tests) SKIP_TESTS=true ;;
    --no-bump) BUMP_BUILD=false ;;
    -h|--help)
      echo "Usage: $0 [--android-only] [--ios-only] [--skip-tests] [--no-bump]"
      exit 0
      ;;
  esac
done

ARGS=()
[[ "$SKIP_TESTS" == true ]] && ARGS+=(--skip-tests)
[[ "$BUMP_BUILD" == false ]] && ARGS+=(--no-bump)

if [[ "$BUMP_BUILD" == true ]]; then
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

if [[ "$SKIP_TESTS" != true ]]; then
  flutter test
fi

if [[ "$BUILD_AAB" == true ]]; then
  echo "==> Android App Bundle"
  ./scripts/build_release_appbundle.sh --no-bump "${ARGS[@]}"
fi

if [[ "$BUILD_IPA" == true ]]; then
  echo "==> iOS IPA"
  ./scripts/build_release_ios.sh --no-bump "${ARGS[@]}"
fi

echo ""
echo "Done. Ship the same pubspec build number to Play and TestFlight."
