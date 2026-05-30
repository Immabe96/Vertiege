#!/usr/bin/env bash
# Pull Firebase app registry + SDK configs for closed beta (Android + iOS).
# Requires: firebase-cli (`brew install firebase-cli`) and `firebase login` once.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
PROJECT="${FIREBASE_PROJECT:-veritage}"

export PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/.pub-cache/bin:$PATH"

if ! command -v firebase >/dev/null 2>&1; then
  echo "Install Firebase CLI: brew install firebase-cli" >&2
  exit 1
fi

if ! firebase projects:list >/dev/null 2>&1; then
  echo "Not logged in. Run once:" >&2
  echo "  firebase login" >&2
  echo "Then re-run: $0" >&2
  exit 1
fi

echo "==> Firebase project: $PROJECT"
firebase use "$PROJECT" >/dev/null 2>&1 || firebase use --add "$PROJECT"

echo ""
echo "==> Registered apps"
firebase apps:list ANDROID --project "$PROJECT" || true
firebase apps:list IOS --project "$PROJECT" || true
firebase apps:list WEB --project "$PROJECT" || true

ANDROID_APP_ID="${ANDROID_FIREBASE_APP_ID:-}"
IOS_APP_ID="${IOS_FIREBASE_APP_ID:-}"

if [ -z "$ANDROID_APP_ID" ]; then
  ANDROID_APP_ID=$(firebase apps:list ANDROID --project "$PROJECT" --json 2>/dev/null \
    | python3 -c "
import json,sys
data=json.load(sys.stdin)
apps=data.get('result',data) if isinstance(data,dict) else data
if not isinstance(apps,list): apps=[]
for a in apps:
  if a.get('platform')=='ANDROID' or 'android' in str(a.get('name','')).lower():
    pkg=(a.get('namespace') or a.get('packageName') or '')
    if pkg=='com.vertiege':
      print(a.get('appId','')); break
else:
  for a in apps:
    if 'android' in str(a.get('appId','')).lower():
      print(a.get('appId','')); break
" 2>/dev/null || true)
fi

if [ -z "$IOS_APP_ID" ]; then
  IOS_APP_ID=$(firebase apps:list IOS --project "$PROJECT" --json 2>/dev/null \
    | python3 -c "
import json,sys
data=json.load(sys.stdin)
apps=data.get('result',data) if isinstance(data,dict) else data
if not isinstance(apps,list): apps=[]
for a in apps:
  if a.get('platform')=='IOS':
    bid=(a.get('namespace') or a.get('bundleId') or '')
    if bid=='com.vertiege':
      print(a.get('appId','')); break
else:
  for a in apps:
    if 'ios' in str(a.get('appId','')).lower():
      print(a.get('appId','')); break
" 2>/dev/null || true)
fi

# Fallbacks from lib/firebase_options.dart / firebase.json
ANDROID_APP_ID="${ANDROID_APP_ID:-1:92526224561:android:7b7a9f6f448f61ca7cae90}"
IOS_APP_ID="${IOS_APP_ID:-1:92526224561:ios:81887c2e30ab2bdd7cae90}"

echo ""
echo "Using Android app: $ANDROID_APP_ID"
echo "Using iOS app:     $IOS_APP_ID"

mkdir -p android/app ios/Runner

echo ""
echo "==> Download google-services.json"
rm -f android/app/google-services.json
firebase apps:sdkconfig ANDROID "$ANDROID_APP_ID" \
  --project "$PROJECT" \
  -o android/app/google-services.json

echo "==> Download GoogleService-Info.plist"
rm -f ios/Runner/GoogleService-Info.plist
firebase apps:sdkconfig IOS "$IOS_APP_ID" \
  --project "$PROJECT" \
  -o ios/Runner/GoogleService-Info.plist

if command -v flutterfire >/dev/null 2>&1; then
  echo ""
  echo "==> flutterfire configure (regenerates lib/firebase_options.dart)"
  flutterfire configure \
    --project="$PROJECT" \
    --platforms=android,ios \
    --android-package-name=com.vertiege \
    --ios-bundle-id=com.vertiege \
    --yes
else
  echo ""
  echo "Tip: dart pub global activate flutterfire_cli && flutterfire configure"
fi

echo ""
echo "==> Beta prereqs"
chmod +x scripts/check_beta_prereqs.sh
./scripts/check_beta_prereqs.sh

echo ""
echo "==> Android SHA fingerprints (Google Sign-In)"
RELEASE_SHA=""
DEBUG_SHA=""
if [[ -f android/key.properties && -f android/upload-keystore.jks ]]; then
  STORE=$(grep '^storePassword=' android/key.properties | cut -d= -f2-)
  RELEASE_SHA=$(keytool -list -v -keystore android/upload-keystore.jks -alias upload -storepass "$STORE" 2>/dev/null \
    | grep 'SHA1:' | head -1 | awk '{print $2}')
fi
if [[ -f "$HOME/.android/debug.keystore" ]]; then
  DEBUG_SHA=$(keytool -list -v -keystore "$HOME/.android/debug.keystore" -alias androiddebugkey \
    -storepass android -keypass android 2>/dev/null | grep 'SHA1:' | head -1 | awk '{print $2}')
fi
for sha in "$RELEASE_SHA" "$DEBUG_SHA"; do
  [[ -z "$sha" ]] && continue
  firebase apps:android:sha:create "$ANDROID_APP_ID" "$sha" --project "$PROJECT" 2>/dev/null \
    && echo "Registered SHA-1: $sha" || echo "SHA-1 already registered or skipped: $sha"
done
firebase apps:android:sha:list "$ANDROID_APP_ID" --project "$PROJECT" 2>/dev/null || true

echo ""
echo "Done. Next: upload AAB / IPA per docs/CLOSED_BETA.md"
