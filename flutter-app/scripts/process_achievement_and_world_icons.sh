#!/usr/bin/env bash
# Remove light mattes from per-id achievement badges and world icon PNGs.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
WITHOUTBG="${WITHOUTBG_CMD:-uvx withoutbg}"
if command -v withoutbg >/dev/null 2>&1; then WITHOUTBG="withoutbg"; fi

BACKUP_DIR="$ROOT/assets/staging/withoutbg-backup/$(date -u +%Y%m%dT%H%M%SZ)"
mkdir -p "$BACKUP_DIR"

mapfile -t FILES < <(
  find "$ROOT/assets/generated/achievements" -maxdepth 1 -name '*.png' 2>/dev/null | sort
  find "$ROOT/assets/generated" -maxdepth 1 -name 'world-icon-*.png' 2>/dev/null | sort
)

echo "→ $WITHOUTBG on ${#FILES[@]} files"
processed=0
failed=0
for src in "${FILES[@]}"; do
  rel="${src#"$ROOT"/}"
  backup="$BACKUP_DIR/$rel"
  tmp="${src}.withoutbg.tmp.png"
  mkdir -p "$(dirname "$backup")"
  echo "▸ $rel"
  cp -a "$src" "$backup"
  if $WITHOUTBG "$src" -o "$tmp"; then
    mv -f "$tmp" "$src"
    echo "$rel" >>"$BACKUP_DIR/processed.txt"
    processed=$((processed + 1))
  else
    rm -f "$tmp"
    echo "  ✗ failed"
    failed=$((failed + 1))
  fi
done
echo "Done: processed=$processed failed=$failed backups=$BACKUP_DIR"
exit $(( failed > 0 ? 1 : 0 ))
