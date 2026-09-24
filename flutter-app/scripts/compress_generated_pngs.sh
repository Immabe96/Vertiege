#!/usr/bin/env bash
# Resize and compress generated PNGs for APK size (512², optimized PNG).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

SIZE="${PNG_SIZE:-512}"
QUALITY="${PNG_QUALITY:-82}"

if ! command -v magick >/dev/null 2>&1; then
  echo "ImageMagick (magick) is required." >&2
  exit 1
fi

mapfile -t FILES < <(
  find "$ROOT/assets/generated/achievements" -maxdepth 1 -name '*.png' 2>/dev/null | sort
  find "$ROOT/assets/generated" -maxdepth 1 \( -name 'world-icon-*.png' -o -name 'badge-*.png' -o -name 'prof-*.png' -o -name 'ach-*.png' -o -name 'tier-*.png' -o -name 'avatar*.png' \) 2>/dev/null | sort
)

if [[ ${#FILES[@]} -eq 0 ]]; then
  echo "No PNGs found."
  exit 0
fi

before=0
after=0
for src in "${FILES[@]}"; do
  bytes=$(stat -c%s "$src")
  before=$((before + bytes))
  tmp="${src}.compress.tmp.png"
  magick "$src" \
    -resize "${SIZE}x${SIZE}>" \
    -strip \
    -alpha on \
    PNG32:"$tmp"
  if command -v pngquant >/dev/null 2>&1; then
    pngquant --quality=65-${QUALITY} --skip-if-larger --force --output "$src" "$tmp" 2>/dev/null || mv -f "$tmp" "$src"
    rm -f "$tmp"
  else
    magick "$tmp" -define png:compression-level=9 -define png:compression-filter=5 "$src"
    rm -f "$tmp"
  fi
  after=$((after + $(stat -c%s "$src")))
done

echo "Compressed ${#FILES[@]} PNGs"
echo "Before: $(numfmt --to=iec $before 2>/dev/null || echo "${before}B")"
echo "After:  $(numfmt --to=iec $after 2>/dev/null || echo "${after}B")"
echo "Saved:  $(numfmt --to=iec $((before - after)) 2>/dev/null || echo "$((before - after))B")"
