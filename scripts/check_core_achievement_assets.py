#!/usr/bin/env python3
"""Exit 0 when every core catalog achievement has raster badge art on disk.

Counts legacy map assets (prof-*, badge-*) and per-id achievements/<id>.png.

  python3 scripts/check_core_achievement_assets.py
  python3 scripts/check_core_achievement_assets.py --json
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CORE_IDS_DART = ROOT / "lib/config/core_achievement_badge_ids.dart"
WORLD_ASSETS = ROOT / "lib/utils/world_assets.dart"


def load_core_ids() -> list[str]:
    ids: list[str] = []
    for line in CORE_IDS_DART.read_text(encoding="utf-8").splitlines():
        s = line.strip().strip(",")
        if s.startswith("'") and s.endswith("'"):
            ids.append(s[1:-1])
    if not ids:
        raise SystemExit(f"No ids in {CORE_IDS_DART}")
    return ids


def load_badge_paths() -> dict[str, str]:
    text = WORLD_ASSETS.read_text(encoding="utf-8")
    block = text.split("_badgeImagePaths = <String, String>{", 1)[-1].split("};", 1)[0]
    return dict(re.findall(r"'([^']+)': 'assets/generated/([^']+)'", block))


def resolved_path(achievement_id: str, badge_map: dict[str, str]) -> Path | None:
    rel = badge_map.get(achievement_id)
    if rel is None:
        rel = f"achievements/{achievement_id}.png"
    return ROOT / "assets/generated" / rel


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--list-missing", action="store_true")
    args = parser.parse_args()

    core_ids = load_core_ids()
    badge_map = load_badge_paths()
    missing: list[str] = []
    ok: list[str] = []

    for aid in core_ids:
        path = resolved_path(aid, badge_map)
        if path and path.is_file():
            ok.append(aid)
        else:
            missing.append(aid)

    payload = {
        "required": len(core_ids),
        "ready": len(ok),
        "missing": len(missing),
        "complete": len(missing) == 0,
        "missingIds": missing[:20] if missing else [],
    }

    if args.json:
        print(json.dumps(payload, indent=2))
    else:
        print(
            f"Core achievement assets: {len(ok)}/{len(core_ids)} ready "
            f"({'COMPLETE' if not missing else f'{len(missing)} missing'})"
        )
        if args.list_missing and missing:
            for aid in missing:
                print(f"  - {aid}")

    sys.exit(0 if not missing else 1)


if __name__ == "__main__":
    main()
