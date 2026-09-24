#!/usr/bin/env bash
# Wave 21: minimal local/CI smoke — requires Docker + Supabase CLI.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"   # flutter-app/
REPO_ROOT="$(cd "$ROOT/.." && pwd)"        # repo root (supabase/ lives there)

echo "== Vertiege Supabase integration smoke =="

if ! command -v supabase >/dev/null 2>&1; then
  echo "SKIP: supabase CLI not installed"
  exit 0
fi

if ! docker info >/dev/null 2>&1; then
  echo "SKIP: Docker not running"
  exit 0
fi

cd "$REPO_ROOT"
supabase start >/dev/null
supabase db reset --yes

echo "OK: migrations applied via db reset"

if command -v flutter >/dev/null 2>&1; then
  cd "$ROOT"
  flutter test test/config/image_cache_policy_test.dart test/services/mutation_outbox_pending_test.dart --no-pub
  echo "OK: flutter smoke tests"
else
  echo "SKIP: flutter not on PATH"
fi

echo "Smoke complete."
