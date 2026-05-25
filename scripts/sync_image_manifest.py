#!/usr/bin/env python3
"""Enqueue missing Vertiege assets into docs/assets/image-manifest.json.

Does NOT generate images — run the asset-generator agent or image_gen.py next.

  python3 scripts/sync_image_manifest.py
  python3 scripts/sync_image_manifest.py --dry-run
"""

from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MANIFEST_PATH = ROOT / "docs/assets/image-manifest.json"

EMBLEM_NEGATIVE = (
    "no text, no letters, no numbers, no words, no labels, no monograms, "
    "transparent background, isolated emblem only, no white square backdrop, "
    "no drop shadow card, do not use generic shiny gold metal for every icon, "
    "each icon must look visually distinct"
)

# Required for 590-achievement catalog (category fallback + dedicated profession art).
REQUIRED_ASSETS: dict[str, dict] = {
    "ach-life": {
        "category": "achievement_category",
        "prompt": (
            "Achievement category icon: compass rose and winding path in warm amber "
            "and soft teal enamel, life-journey pin badge, hopeful and personal, "
            "not generic gold trophy."
        ),
    },
    "ach-profession": {
        "category": "achievement_category",
        "prompt": (
            "Achievement category icon: wax seal stamp with laurel ring in deep violet "
            "enamel and brushed silver rim, verified credential mood, professional crest."
        ),
    },
    "prof-nurse": {
        "category": "profession",
        "prompt": (
            "Profession icon medallion: nurse cap silhouette with teal cross accent "
            "on soft mint enamel disc, caring clinical pin, distinct from doctor stethoscope."
        ),
    },
    "prof-teacher": {
        "category": "profession",
        "prompt": (
            "Profession icon medallion: open book with chalk and apple motif in "
            "cobalt blue and cream enamel, education pin, scholarly not childish."
        ),
    },
    "prof-architect": {
        "category": "profession",
        "prompt": (
            "Profession icon medallion: drafting triangle and skyline arc in graphite "
            "silver and sandstone enamel, architecture pin, precise and modern."
        ),
    },
    "prof-scientist": {
        "category": "profession",
        "prompt": (
            "Profession icon medallion: flask and atom orbit in cyan and white enamel "
            "on midnight blue disc, research science pin, clean lab aesthetic."
        ),
    },
    "prof-chef": {
        "category": "profession",
        "prompt": (
            "Profession icon medallion: chef hat and whisk in warm cream and copper "
            "enamel, culinary pin, appetizing not cartoon chef face."
        ),
    },
    "prof-realtor": {
        "category": "profession",
        "prompt": (
            "Profession icon medallion: house key over terracotta roof line in bronze "
            "and slate enamel, real estate pin, trustworthy home motif."
        ),
    },
    "prof-therapist": {
        "category": "profession",
        "prompt": (
            "Profession icon medallion: gentle infinity loop heart in lavender and soft "
            "green enamel, mental wellness pin, calm and supportive."
        ),
    },
    "prof-journalist": {
        "category": "profession",
        "prompt": (
            "Profession icon medallion: press microphone and ink pen nib in charcoal "
            "and newsprint gray enamel with red accent dot, journalism pin, no letters."
        ),
    },
}


def new_item(asset_id: str, spec: dict) -> dict:
    filename = f"{asset_id}.png"
    return {
        "id": asset_id,
        "filename": filename,
        "category": spec["category"],
        "format": "png",
        "transparent": True,
        "size": "512x512",
        "noText": True,
        "status": "pending",
        "prompt": spec["prompt"],
        "negativePrompt": EMBLEM_NEGATIVE,
        "stagingPath": f"assets/staging/generated/{filename}",
        "finalPath": f"assets/generated/{filename}",
        "generatedAt": None,
        "approvedAt": None,
        "notes": "enqueued by sync_image_manifest.py",
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    if not MANIFEST_PATH.exists():
        raise SystemExit("Run image_gen.ps1 init first or restore image-manifest.json")

    manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8-sig"))
    existing_ids = {i["id"] for i in manifest["items"]}
    added: list[str] = []

    for asset_id, spec in REQUIRED_ASSETS.items():
        if asset_id in existing_ids:
            continue
        item = new_item(asset_id, spec)
        if args.dry_run:
            print(f"would add: {asset_id}")
        else:
            manifest["items"].append(item)
        added.append(asset_id)

    if args.dry_run:
        print(f"\n{len(added)} item(s) would be added.")
        return

    if not added:
        print("Manifest already has all required assets.")
        return

    manifest["updatedAt"] = datetime.now(timezone.utc).isoformat()
    MANIFEST_PATH.write_text(
        json.dumps(manifest, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    print(f"Added {len(added)} item(s): {', '.join(added)}")
    print("Next: python3 scripts/image_gen.py next --json")


if __name__ == "__main__":
    main()
