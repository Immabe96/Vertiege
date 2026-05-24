#!/usr/bin/env bash
# Generate release keystore + android/key.properties for local signed APK builds.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
KEYSTORE="$ROOT/android/upload-keystore.jks"
PROPS="$ROOT/android/key.properties"

if [[ -f "$KEYSTORE" && -f "$PROPS" ]]; then
  echo "Signing already configured:"
  echo "  $KEYSTORE"
  echo "  $PROPS"
  exit 0
fi

if ! command -v keytool >/dev/null 2>&1; then
  echo "keytool not found. Install a JDK (e.g. pacman -S jdk-openjdk)." >&2
  exit 1
fi

STORE_PASS="$(openssl rand -base64 24 | tr -d '/+=' | head -c 24)"
KEY_PASS="$STORE_PASS"

keytool -genkeypair -v \
  -keystore "$KEYSTORE" \
  -storepass "$STORE_PASS" \
  -keypass "$KEY_PASS" \
  -alias upload \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -dname "CN=Vertiege, OU=Mobile, O=Vertiege, L=Unknown, ST=Unknown, C=US"

cat >"$PROPS" <<EOF
storePassword=$STORE_PASS
keyPassword=$KEY_PASS
keyAlias=upload
storeFile=upload-keystore.jks
EOF

chmod 600 "$PROPS"

echo "Created:"
echo "  $KEYSTORE"
echo "  $PROPS"
echo ""
echo "Back up the keystore and passwords (see docs/superpowers/specs/keystore-backup.md)."
echo "Passwords are stored only in android/key.properties on this machine."
