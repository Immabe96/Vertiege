#!/usr/bin/env bash
# Wave 13: fail CI if service_role key material appears in client lib/.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if rg -n 'service_role' "$ROOT/lib" 2>/dev/null; then
  echo "error: service_role must not appear under lib/"
  exit 1
fi
echo "ok: no service_role references in lib/"
