#!/usr/bin/env bash
# Validate commune UX assets listed in discord-redesign-asset-manifest.json
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MANIFEST="$ROOT/docs/assets/discord-redesign-asset-manifest.json"
cd "$ROOT"

if ! command -v python3 >/dev/null; then
  echo "python3 required" >&2
  exit 1
fi

python3 <<'PY'
import json
from pathlib import Path

root = Path(".")
manifest = json.loads((root / "docs/assets/discord-redesign-asset-manifest.json").read_text())
missing = []
optional_missing = []
for a in manifest["assets"]:
    p = root / a["path"]
    if p.exists():
        continue
    if a.get("optional"):
        optional_missing.append(a["id"])
    else:
        missing.append((a["id"], a["path"]))

print(f"Commune assets: {len(manifest['assets'])} defined")
print(f"Present: {len(manifest['assets']) - len(missing) - len(optional_missing)}")
if optional_missing:
    print(f"Optional missing ({len(optional_missing)}): {', '.join(optional_missing[:5])}{'...' if len(optional_missing)>5 else ''}")
if missing:
    print(f"\nMISSING required ({len(missing)}):")
    for id_, path in missing[:20]:
        print(f"  {id_}: {path}")
    if len(missing) > 20:
        print(f"  ... and {len(missing)-20} more")
    exit(1)
print("All required commune UX assets present.")
PY
