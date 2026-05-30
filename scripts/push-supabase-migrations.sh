#!/usr/bin/env bash
# Push pending migrations to remote wjaphoaxalvgjnrwqjwe.
# Requires: supabase CLI + `supabase login` (or SUPABASE_ACCESS_TOKEN).
set -euo pipefail
cd "$(dirname "$0")/.."

if ! command -v supabase >/dev/null 2>&1; then
  echo "Install: brew install supabase/tap/supabase"
  exit 1
fi

if [[ -z "${SUPABASE_ACCESS_TOKEN:-}" ]]; then
  echo "Run: supabase login"
  echo "Or: export SUPABASE_ACCESS_TOKEN=..."
  exit 1
fi

supabase link --project-ref wjaphoaxalvgjnrwqjwe --yes
supabase migration list --linked
supabase db push --linked --yes
echo "Done."
