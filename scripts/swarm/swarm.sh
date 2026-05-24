#!/usr/bin/env bash
# Vertiege local Agent Swarm (Cursor CLI, composer-2.5 only).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export SWARM_ROOT="$ROOT"
cd "$ROOT"

if ! command -v "${AGENT_BIN:-agent}" >/dev/null 2>&1; then
  echo "error: Cursor Agent CLI not found. Install: https://cursor.com/docs/cli" >&2
  exit 1
fi

exec node "$ROOT/scripts/swarm/swarm.mjs" "$@"
