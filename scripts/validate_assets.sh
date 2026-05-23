#!/usr/bin/env bash
# Cross-platform wrapper for asset validation (CI on Linux/macOS).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if command -v pwsh >/dev/null 2>&1; then
  pwsh -NoProfile -File "$ROOT/scripts/validate_assets.ps1" "$@"
elif command -v powershell >/dev/null 2>&1; then
  powershell -NoProfile -ExecutionPolicy Bypass -File "$ROOT/scripts/validate_assets.ps1" "$@"
else
  echo "PowerShell (pwsh) required to run validate_assets.ps1" >&2
  exit 1
fi
