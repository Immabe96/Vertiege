#!/usr/bin/env bash
# Runs `flutter run` with a command fifo so agents/scripts can hot-restart via:
#   scripts/hot_restart.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEVICE="${1:-emulator-5554}"
FIFO="${VERTIEGE_FLUTTER_FIFO:-${TMPDIR:-/tmp}/vertiege_flutter.cmd.fifo}"
PIDFILE="${TMPDIR:-/tmp}/vertiege_flutter.pid"
LOG="${TMPDIR:-/tmp}/vertiege_flutter.log}"

cd "$ROOT"

rm -f "$FIFO"
mkfifo "$FIFO"

echo "Device: $DEVICE"
echo "Command fifo: $FIFO (hot restart: scripts/hot_restart.sh)"
echo "Log: $LOG"

# Keep fifo open; each line is forwarded to flutter run (R = hot restart).
cat "$FIFO" | flutter run -d "$DEVICE" 2>&1 | tee "$LOG"
