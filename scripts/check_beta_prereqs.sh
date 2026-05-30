#!/usr/bin/env bash
# Pre-flight checks before shipping a closed-beta build.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

FAIL=0
warn() { echo "WARN: $*"; }
ok() { echo "OK:   $*"; }
bad() { echo "FAIL: $*"; FAIL=1; }

echo "==> Vertiege closed-beta prereqs"
echo ""

# Version
if grep -qE '^version: .+\+[0-9]+' pubspec.yaml; then
  ok "pubspec version $(grep '^version:' pubspec.yaml | head -1)"
else
  bad "pubspec.yaml missing version: NAME+BUILD"
fi

# Env
if [[ -f .env ]]; then
  if grep -q 'SUPABASE_URL=https://' .env && grep -q 'SUPABASE_ANON_KEY=' .env; then
    ok ".env has Supabase URL and anon key"
  else
    bad ".env missing SUPABASE_URL or SUPABASE_ANON_KEY"
  fi
else
  warn "No .env — release builds need Supabase keys in .env (or CI secrets)"
fi

# Android Firebase
if [[ -f android/app/google-services.json ]]; then
  if grep -q '"package_name": "com.vertiege"' android/app/google-services.json 2>/dev/null; then
    ok "google-services.json package com.vertiege"
  else
    warn "google-services.json present but package_name may not be com.vertiege"
  fi
else
  bad "android/app/google-services.json missing"
fi

# Android signing
if [[ -f android/key.properties && -f android/upload-keystore.jks ]]; then
  ok "Android release keystore configured"
elif [[ -f android/key.properties ]]; then
  warn "key.properties exists but upload-keystore.jks missing"
else
  warn "Android signing not configured — APK/AAB will be debug-signed (not for Play)"
fi

# iOS Firebase (local Mac builds)
if [[ -f ios/Runner/GoogleService-Info.plist ]]; then
  ok "GoogleService-Info.plist present"
elif grep -q "ios:81887c2e30ab2bdd7cae90" lib/firebase_options.dart 2>/dev/null; then
  ok "iOS Firebase in lib/firebase_options.dart (run ./scripts/firebase_beta_sync.sh for plist)"
else
  warn "ios/Runner/GoogleService-Info.plist missing — run ./scripts/firebase_beta_sync.sh after firebase login"
fi

# iOS URL scheme (OAuth)
if grep -q 'vertiege' ios/Runner/Info.plist 2>/dev/null; then
  ok "iOS URL scheme vertiege:// configured"
else
  bad "ios/Runner/Info.plist missing vertiege URL scheme"
fi

# Core assets (release script gate)
if python3 scripts/check_core_achievement_assets.py >/dev/null 2>&1; then
  ok "Core achievement badge assets complete"
else
  warn "Core achievement assets incomplete — run scripts/check_core_achievement_assets.py"
fi

echo ""
if [[ "$FAIL" -eq 0 ]]; then
  echo "Prereqs passed (warnings are OK for sideload-only Android)."
  exit 0
fi
echo "Fix failures before store submission."
exit 1
