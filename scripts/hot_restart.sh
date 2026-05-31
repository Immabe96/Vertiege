#!/usr/bin/env bash
# Sends "R" (hot restart) to an active `scripts/dev_run.sh` Flutter session.
set -euo pipefail

FIFO="${VERTIEGE_FLUTTER_FIFO:-${TMPDIR:-/tmp}/vertiege_flutter.cmd.fifo}"

if [[ ! -p "$FIFO" ]]; then
  echo "No Flutter dev session (missing fifo: $FIFO)." >&2
  echo "Start one with: scripts/dev_run.sh [device-id]" >&2
  exit 1
fi

printf 'R\n' >"$FIFO"
echo "Hot restart sent."
