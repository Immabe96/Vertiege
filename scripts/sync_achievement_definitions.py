#!/usr/bin/env python3
"""Emit Supabase migration rows from lib/config/achievements*.dart."""

from __future__ import annotations

import re
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CATALOG_FILES = [
    ROOT / "lib/config/achievements.dart",
    ROOT / "lib/config/achievements_bulk_seeds.dart",
    ROOT / "lib/config/achievements_bulk_seeds_v2.dart",
    ROOT / "lib/config/achievements_bulk_seeds_v3.dart",
]
MIGRATIONS = ROOT / "supabase/migrations"


def parse_catalog(paths: list[Path]) -> list[tuple[str, int, bool]]:
    rows: list[tuple[str, int, bool]] = []
    for path in paths:
        if not path.exists():
            continue
        text = path.read_text()
        for block in re.finditer(
            r"Achievement\(\s*(.*?)\n\s*\),", text, re.DOTALL
        ):
            b = block.group(1)
            m_id = re.search(r"id: '([^']+)'", b)
            m_xp = re.search(r"xpValue: (\d+)", b)
            m_cat = re.search(r"category: AchievementCategory\.(\w+)", b)
            if not (m_id and m_xp and m_cat):
                continue
            rows.append(
                (m_id.group(1), int(m_xp.group(1)), m_cat.group(1) == "inApp")
            )
    return rows


def main() -> None:
    existing = [p for p in CATALOG_FILES if p.exists()]
    rows = parse_catalog(existing)
    ids = [r[0] for r in rows]
    if len(ids) != len(set(ids)):
        from collections import Counter

        dupes = [k for k, v in Counter(ids).items() if v > 1]
        raise SystemExit(f"Duplicate achievement ids: {dupes[:10]}")

    stamp = datetime.now(timezone.utc).strftime("%Y%m%d%H%M%S")
    out = MIGRATIONS / f"{stamp}_achievement_catalog_sync.sql"
    lines = [
        "-- Sync achievement_definitions with Flutter catalog.",
        f"-- {len(rows)} entries from: "
        + ", ".join(p.name for p in existing),
        "",
        "INSERT INTO public.achievement_definitions (id, xp_value, is_in_app) VALUES",
    ]
    for i, (aid, xp, in_app) in enumerate(rows):
        tail = "," if i < len(rows) - 1 else ""
        lines.append(
            f"  ('{aid}', {xp}, {'true' if in_app else 'false'}){tail}"
        )
    lines += [
        "ON CONFLICT (id) DO UPDATE",
        "  SET xp_value = EXCLUDED.xp_value,",
        "      is_in_app = EXCLUDED.is_in_app;",
        "",
    ]
    out.write_text("\n".join(lines))
    print(f"Wrote {out} ({len(rows)} achievements)")


if __name__ == "__main__":
    main()
