#!/usr/bin/env bash
# UI/UX audit via Cursor Swarm (research preset, composer-2.5 only).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
exec "$ROOT/scripts/swarm/swarm.sh" audit-ui "$@"
