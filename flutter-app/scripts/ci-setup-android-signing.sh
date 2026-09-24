#!/usr/bin/env bash
# Write android/key.properties + upload-keystore.jks from GitHub Actions secrets.
# Required repo secrets (Settings → Secrets and variables → Actions):
#   ANDROID_KEYSTORE_BASE64  — base64 -w0 android/upload-keystore.jks
#   ANDROID_KEYSTORE_PASSWORD
#   ANDROID_KEY_PASSWORD
# Optional:
#   ANDROID_KEY_ALIAS        — default: upload
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
KEYSTORE="$ROOT/android/upload-keystore.jks"
PROPS="$ROOT/android/key.properties"
ALIAS="${ANDROID_KEY_ALIAS:-upload}"

if [[ -z "${ANDROID_KEYSTORE_BASE64:-}" ]]; then
  echo "::warning::ANDROID_KEYSTORE_BASE64 not set — release APK will use debug signing"
  exit 0
fi
if [[ -z "${ANDROID_KEYSTORE_PASSWORD:-}" || -z "${ANDROID_KEY_PASSWORD:-}" ]]; then
  echo "::warning::ANDROID_KEYSTORE_PASSWORD / ANDROID_KEY_PASSWORD not set — debug signing"
  exit 0
fi

# GitHub secret paste may include newlines/spaces — strip before decode.
CLEAN_B64="$(printf '%s' "$ANDROID_KEYSTORE_BASE64" | tr -d '[:space:]')"
if ! printf '%s' "$CLEAN_B64" | base64 -d >"$KEYSTORE" 2>/dev/null; then
  echo "::error::ANDROID_KEYSTORE_BASE64 is not valid base64. Re-set with: base64 -i android/upload-keystore.jks | tr -d '\\n'"
  exit 1
fi
cat >"$PROPS" <<EOF
storePassword=$ANDROID_KEYSTORE_PASSWORD
keyPassword=$ANDROID_KEY_PASSWORD
keyAlias=$ALIAS
storeFile=upload-keystore.jks
EOF

echo "Release signing configured (alias=$ALIAS)"
