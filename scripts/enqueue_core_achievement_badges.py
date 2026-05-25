#!/usr/bin/env python3
"""Enqueue bespoke badge art for core catalog (~110) achievements.

Writes:
  - docs/assets/image-manifest.json (achievement_badge rows, pending)
  - lib/config/core_achievement_badge_ids.dart (runtime path convention)

Does not generate pixels — use vertiege-asset-generator agent.

  python3 scripts/enqueue_core_achievement_badges.py
  python3 scripts/enqueue_core_achievement_badges.py --dry-run
"""

from __future__ import annotations

import argparse
import json
import re
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ACHIEVEMENTS_DART = ROOT / "lib/config/achievements.dart"
WORLD_ASSETS = ROOT / "lib/utils/world_assets.dart"
MANIFEST_PATH = ROOT / "docs/assets/image-manifest.json"
CORE_IDS_DART = ROOT / "lib/config/core_achievement_badge_ids.dart"

RAW_MARKER_START = "const List<Achievement> _achievementCatalogRaw = ["
RAW_MARKER_END = "];\n\n/// Resolved catalog"

EMBLEM_NEGATIVE = (
    "no text, no letters, no numbers, no words, no labels, no monograms, "
    "transparent background, isolated emblem only, no white square backdrop, "
    "no drop shadow card, do not use generic shiny gold metal for every icon, "
    "each icon must look visually distinct"
)

# Category art direction (matches approved badge finesse in image_gen.ps1).
CATEGORY_VISUAL = {
    "education": (
        "scholastic art-deco enamel, navy and ivory, books scroll or cap motif, "
        "refined academic crest"
    ),
    "career": (
        "executive burgundy leather and brushed brass clasp, briefcase or rising "
        "chart abstract, professional not cheesy gold trophy"
    ),
    "relationships": (
        "rose quartz and coral enamel, interlocking hearts or linked rings, "
        "warm romantic pin-badge"
    ),
    "health": (
        "matte charcoal and neon green fitness ring, dumbbell pulse or stride "
        "silhouette, sporty clean icon"
    ),
    "skills": (
        "forged iron and orange spark, tools or craft motif matching the skill, "
        "rugged maker badge"
    ),
    "travel": (
        "sky-blue enamel and white contrail, compass or landmark silhouette, "
        "wanderlust travel sticker aesthetic"
    ),
    "finance": (
        "emerald crystal and cool silver chrome, coins or growth bars abstract, "
        "no yellow gold clipart"
    ),
    "community": (
        "warm copper and terracotta on slate, handshake or helping hands patch, "
        "human welcoming community crest"
    ),
    "funny": (
        "glossy playful plastic, hot pink and teal, comedy chaos prop related "
        "to the joke, bold cartoon game pin not horror"
    ),
    "creative": (
        "iridescent foil and rainbow paint splash, palette mic pen or stage "
        "motif, colorful creative emblem"
    ),
    "life": (
        "amber and soft teal life-journey enamel, personal milestone object "
        "from the story, hopeful not generic trophy"
    ),
    "profession": (
        "verified credential wax seal and laurel, vocation-specific tool on "
        "violet enamel disc, premium profession pin"
    ),
    "inApp": (
        "Vertiege realm UI motif, violet and gold accent glow, streak flame "
        "or realm symbol, digital prestige pin"
    ),
}


def parse_core_achievements() -> list[dict]:
    text = ACHIEVEMENTS_DART.read_text(encoding="utf-8")
    start = text.index(RAW_MARKER_START) + len(RAW_MARKER_START)
    end = text.index(RAW_MARKER_END)
    chunk = text[start:end]
    blocks = re.findall(r"Achievement\(\s*(.*?)\n\s*\),", chunk, re.DOTALL)
    rows: list[dict] = []
    for block in blocks:
        m_id = re.search(r"id: '([^']+)'", block)
        m_title = re.search(r"title: '([^']+)'", block)
        m_desc = re.search(r"description: '([^']+)'", block)
        m_cat = re.search(r"category: AchievementCategory\.(\w+)", block)
        if not all([m_id, m_title, m_desc, m_cat]):
            continue
        rows.append(
            {
                "id": m_id.group(1),
                "title": m_title.group(1).replace("\\'", "'"),
                "description": m_desc.group(1).replace("\\'", "'"),
                "category": m_cat.group(1),
                "is_funny": "isFunny: true" in block,
            }
        )
    return rows


def existing_badge_map_keys() -> set[str]:
    text = WORLD_ASSETS.read_text(encoding="utf-8")
    return set(re.findall(r"'([^']+)': 'assets/generated/", text))


def build_prompt(row: dict) -> str:
    cat = row["category"]
    visual = CATEGORY_VISUAL.get(cat, CATEGORY_VISUAL["life"])
    tone = "Playful meme energy. " if row["is_funny"] or cat == "funny" else ""
    return (
        f"Vertiege game achievement badge medallion for milestone: {row['title']}. "
        f"Meaning: {row['description']}. "
        f"{tone}"
        f"Category: {cat}. Style: {visual}. "
        "512x512 square isolated emblem, premium mobile RPG pin illustration "
        "with gentle depth and polish like badge-doctor and badge-marathon, "
        "readable at 48dp on AMOLED dark UI, unique silhouette for this achievement only."
    )


def new_manifest_item(row: dict) -> dict:
    aid = row["id"]
    filename = f"achievements/{aid}.png"
    return {
        "id": aid,
        "filename": filename,
        "category": "achievement_badge",
        "format": "png",
        "transparent": True,
        "size": "512x512",
        "noText": True,
        "status": "pending",
        "prompt": build_prompt(row),
        "negativePrompt": EMBLEM_NEGATIVE,
        "stagingPath": f"assets/staging/generated/{filename}",
        "finalPath": f"assets/generated/{filename}",
        "generatedAt": None,
        "approvedAt": None,
        "notes": "core catalog bespoke badge (enqueue_core_achievement_badges.py)",
    }


def write_core_ids_dart(ids: list[str]) -> None:
    lines = [
        "// GENERATED by scripts/enqueue_core_achievement_badges.py — do not edit.",
        "// Core catalog achievements use assets/generated/achievements/<id>.png when present.",
        "",
        "const Set<String> coreAchievementBadgeIds = {",
    ]
    for aid in ids:
        lines.append(f"  '{aid}',")
    lines.append("};")
    lines.append("")
    CORE_IDS_DART.write_text("\n".join(lines), encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    core = parse_core_achievements()
    if not core:
        raise SystemExit("No core achievements parsed — check achievements.dart markers")

    explicit = existing_badge_map_keys()
    manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8-sig"))
    by_id = {i["id"]: i for i in manifest["items"]}

    to_add: list[dict] = []
    core_ids: list[str] = []

    for row in core:
        aid = row["id"]
        core_ids.append(aid)
        if aid in explicit:
            continue
        existing = by_id.get(aid)
        if existing and existing.get("category") == "achievement_badge":
            if existing["status"] in ("approved", "generated"):
                continue
        if existing and existing["status"] != "skipped":
            # Refresh prompt for pending core badges
            if args.dry_run:
                print(f"update prompt: {aid}")
            else:
                existing.update(new_manifest_item(row))
            continue
        to_add.append(row)
        if args.dry_run:
            print(f"add: {aid} — {row['title']}")
        else:
            manifest["items"].append(new_manifest_item(row))

    if args.dry_run:
        print(f"\nCore catalog: {len(core)} achievements")
        print(f"New manifest rows: {len(to_add)}")
        print(f"Skipped (explicit world_assets map): {sum(1 for r in core if r['id'] in explicit)}")
        return

    write_core_ids_dart(core_ids)
    manifest["updatedAt"] = datetime.now(timezone.utc).isoformat()
    MANIFEST_PATH.write_text(
        json.dumps(manifest, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    (ROOT / "assets/generated/achievements").mkdir(parents=True, exist_ok=True)
    (ROOT / "assets/staging/generated/achievements").mkdir(parents=True, exist_ok=True)
    print(f"Core ids file: {len(core_ids)} entries -> {CORE_IDS_DART.name}")
    print(f"Manifest: added {len(to_add)} pending achievement_badge row(s)")
    print("Next: python3 scripts/image_gen.py next --json")


if __name__ == "__main__":
    main()
