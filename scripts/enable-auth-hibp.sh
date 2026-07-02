#!/usr/bin/env bash
# Enable HaveIBeenPwned leaked-password protection on the linked remote project.
# Requires: Supabase Pro (or higher) — Free plan returns HTTP 402.
# Auth: `supabase login` (token in macOS keychain) or SUPABASE_ACCESS_TOKEN.
set -euo pipefail

PROJECT_REF="${SUPABASE_PROJECT_REF:-wjaphoaxalvgjnrwqjwe}"

token_from_keychain() {
  local raw
  raw="$(security find-generic-password -a supabase -s "Supabase CLI" -w 2>/dev/null || true)"
  if [[ -z "$raw" ]]; then
    return 1
  fi
  echo "${raw#go-keyring-base64:}" | base64 -d 2>/dev/null
}

TOKEN="${SUPABASE_ACCESS_TOKEN:-}"
if [[ -z "$TOKEN" ]]; then
  TOKEN="$(token_from_keychain || true)"
fi
if [[ -z "$TOKEN" ]]; then
  echo "Run: supabase login"
  echo "Or: export SUPABASE_ACCESS_TOKEN=..."
  exit 1
fi

RESP="$(curl -sS -w "\n%{http_code}" -X PATCH \
  "https://api.supabase.com/v1/projects/${PROJECT_REF}/config/auth" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"password_hibp_enabled": true}')"

BODY="${RESP%$'\n'*}"
CODE="${RESP##*$'\n'}"

if [[ "$CODE" == "200" ]]; then
  echo "Leaked password protection enabled on ${PROJECT_REF}."
  exit 0
fi

echo "Failed (HTTP ${CODE}): ${BODY}"
exit 1
