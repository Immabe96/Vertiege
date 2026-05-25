#!/usr/bin/env bash
# Batch-remove light mattes from transparent PNG assets using withoutbg (local, no API key).
#
# First run downloads ~320MB of ONNX weights from Hugging Face (one-time).
# Requires: python3, uv (for `uvx withoutbg`) or a `withoutbg` CLI on PATH.
#
# Usage:
#   ./scripts/process-transparent-assets.sh              # assets/generated/*.png (manifest)
#   ./scripts/process-transparent-assets.sh --staging  # assets/staging/generated/
#   ./scripts/process-transparent-assets.sh --dry-run
#   ./scripts/process-transparent-assets.sh --limit 3
#   ./scripts/process-transparent-assets.sh --category badge,profession
#
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

TARGET_DIR="assets/generated"
DRY_RUN=false
LIMIT=""
CATEGORIES=""
FORCE=false
VERBOSE=false
WITHOUTBG="${WITHOUTBG_CMD:-uvx withoutbg}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --staging) TARGET_DIR="assets/staging/generated" ;;
    --dry-run) DRY_RUN=true ;;
    --force) FORCE=true ;;
    --verbose|-v) VERBOSE=true ;;
    --limit) LIMIT="$2"; shift ;;
    --category) CATEGORIES="$2"; shift ;;
    --help|-h)
      sed -n '2,18p' "$0"
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
  shift
done

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 is required." >&2
  exit 1
fi

if ! command -v uv >/dev/null 2>&1 && ! command -v withoutbg >/dev/null 2>&1; then
  echo "Install uv (https://docs.astral.sh/uv/) or put 'withoutbg' on PATH." >&2
  exit 1
fi

if command -v withoutbg >/dev/null 2>&1; then
  WITHOUTBG="withoutbg"
fi

MANIFEST="$ROOT/docs/assets/image-manifest.json"
BACKUP_DIR="$ROOT/assets/staging/withoutbg-backup/$(date -u +%Y%m%dT%H%M%SZ)"

mapfile -t FILES < <(
  python3 - "$ROOT" "$MANIFEST" "$TARGET_DIR" "$CATEGORIES" <<'PY'
import json, sys
from pathlib import Path

root = Path(sys.argv[1])
manifest_path = Path(sys.argv[2])
target_dir = sys.argv[3]
categories_filter = sys.argv[4].strip()

transparent_categories = {
    "badge",
    "profession",
    "achievement_category",
    "tier",
    "avatar",
}
if categories_filter:
    transparent_categories = {
        c.strip() for c in categories_filter.split(",") if c.strip()
    }

paths: list[str] = []
seen: set[str] = set()

if manifest_path.is_file():
    data = json.loads(manifest_path.read_text(encoding="utf-8-sig"))
    use_staging = target_dir.rstrip("/").endswith("staging/generated")
    for item in data.get("items", []):
        if item.get("format") != "png":
            continue
        if not item.get("transparent"):
            continue
        cat = item.get("category", "")
        if cat not in transparent_categories:
            continue
        rel = item.get("stagingPath") if use_staging else item.get("finalPath")
        if not rel:
            rel = f"{target_dir}/{item.get('filename', '')}"
        if not rel:
            continue
        p = root / rel
        if p.is_file() and str(p) not in seen:
            seen.add(str(p))
            paths.append(str(p))

# Fallback glob for anything in target_dir not listed in manifest
base = root / target_dir
if base.is_dir():
    for pattern in (
        "badge-*.png",
        "prof-*.png",
        "ach-*.png",
        "tier-*.png",
        "avatar*.png",
    ):
        for p in sorted(base.glob(pattern)):
            if str(p) not in seen:
                seen.add(str(p))
                paths.append(str(p))

for p in sorted(paths):
    print(p)
PY
)

if [[ ${#FILES[@]} -eq 0 ]]; then
  echo "No transparent PNGs found under $TARGET_DIR."
  exit 0
fi

if [[ -n "$LIMIT" ]]; then
  FILES=("${FILES[@]:0:$LIMIT}")
fi

echo "→ withoutbg: $WITHOUTBG (local open-source model, no API key)"
echo "→ Target: $TARGET_DIR (${#FILES[@]} files)"
echo "→ Backups: $BACKUP_DIR"
echo ""

mkdir -p "$BACKUP_DIR"
processed=0
skipped=0
failed=0

for src in "${FILES[@]}"; do
  rel="${src#"$ROOT"/}"
  base="$(basename "$src")"
  backup="$BACKUP_DIR/$rel"
  tmp="${src}.withoutbg.tmp.png"

  mkdir -p "$(dirname "$backup")"

  if [[ "$DRY_RUN" == true ]]; then
    echo "• would process: $rel"
    processed=$((processed + 1))
    continue
  fi

  echo "▸ $rel"
  cp -a "$src" "$backup"

  set +e
  if [[ "$VERBOSE" == true ]]; then
    $WITHOUTBG "$src" -o "$tmp" -v
  else
    $WITHOUTBG "$src" -o "$tmp"
  fi
  status=$?
  set -e

  if [[ $status -ne 0 || ! -f "$tmp" ]]; then
    echo "  ✗ failed (backup kept at $backup)"
    rm -f "$tmp"
    failed=$((failed + 1))
    continue
  fi

  mv -f "$tmp" "$src"
  echo "$rel" >>"$BACKUP_DIR/processed.txt"
  processed=$((processed + 1))
done

echo ""
echo "Done: processed=$processed skipped=$skipped failed=$failed"
if [[ "$DRY_RUN" == true ]]; then
  echo "(dry-run — no files changed)"
elif [[ $processed -gt 0 ]]; then
  echo "Review on dark UI, then: git add $TARGET_DIR"
  echo "Backups + log: $BACKUP_DIR"
fi

[[ $failed -eq 0 ]]
