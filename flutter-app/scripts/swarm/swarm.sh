#!/usr/bin/env bash
# Vertiege local Agent Swarm (Cursor CLI, composer-2.5 only).
set -euo pipefail
# swarm/ sits at flutter-app/scripts/swarm. Agents audit the whole repo
# (docs/, .cursor/, flutter-app/lib/), so SWARM_ROOT must be the repo root, while the
# orchestrator itself lives under flutter-app/.
FLUTTER_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
REPO_ROOT="$(cd "$FLUTTER_ROOT/.." && pwd)"
export SWARM_ROOT="$REPO_ROOT"
cd "$REPO_ROOT"

if ! command -v "${AGENT_BIN:-agent}" >/dev/null 2>&1; then
  echo "error: Cursor Agent CLI not found. Install: https://cursor.com/docs/cli" >&2
  exit 1
fi

exec node "$FLUTTER_ROOT/scripts/swarm/swarm.mjs" "$@"
