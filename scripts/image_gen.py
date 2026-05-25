#!/usr/bin/env python3
"""Resumable image queue for Vertiege (Linux/macOS/Cursor agents).

Usage:
  python3 scripts/image_gen.py status
  python3 scripts/image_gen.py next [--json]
  python3 scripts/image_gen.py mark --id ach-life --status generated
  python3 scripts/image_gen.py promote [--id ach-life] [--all]
  python3 scripts/image_gen.py list [--status pending]
"""

from __future__ import annotations

import argparse
import json
import shutil
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MANIFEST_PATH = ROOT / "docs/assets/image-manifest.json"
STAGING_DIR = ROOT / "assets/staging/generated"
FINAL_DIR = ROOT / "assets/generated"
LOG_PATH = ROOT / "docs/assets/generation-log.md"

EMBLEM_NEGATIVE = (
    "no text, no letters, no numbers, no words, no labels, no monograms, "
    "transparent background, isolated emblem only, no white square backdrop, "
    "no drop shadow card, do not use generic shiny gold metal for every icon, "
    "each icon must look visually distinct"
)


def _utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def load_manifest() -> dict:
    if not MANIFEST_PATH.exists():
        raise SystemExit(f"Missing manifest: {MANIFEST_PATH}")
    return json.loads(MANIFEST_PATH.read_text(encoding="utf-8-sig"))


def save_manifest(manifest: dict) -> None:
    manifest["updatedAt"] = _utc_now()
    MANIFEST_PATH.write_text(
        json.dumps(manifest, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )


def staging_file(item: dict) -> Path:
    return ROOT / item["stagingPath"]


def final_file(item: dict) -> Path:
    return ROOT / item["finalPath"]


def sync_status_from_disk(manifest: dict) -> None:
    for item in manifest["items"]:
        if item["status"] in ("approved", "skipped"):
            continue
        if staging_file(item).is_file():
            if item["status"] in ("pending", "failed"):
                item["status"] = "generated"
            item.setdefault("generatedAt", _utc_now())


def get_next_item(manifest: dict) -> dict | None:
    order = {"failed": 0, "pending": 1}

    def priority(item: dict) -> int:
        # Core per-achievement badges before category icons / misc.
        if item.get("category") == "achievement_badge":
            return 0
        if item.get("category") == "achievement_category":
            return 1
        return 2

    candidates = [
        i
        for i in manifest["items"]
        if i["status"] in ("pending", "failed")
    ]
    if not candidates:
        return None
    candidates.sort(
        key=lambda i: (
            priority(i),
            order.get(i["status"], 9),
            i["id"],
        )
    )
    return candidates[0]


def build_chatgpt_prompt(item: dict) -> str:
    transparent = item.get("transparent")
    fmt = item.get("format", "png")
    if transparent:
        format_hint = "PNG with transparent background (alpha channel)."
    elif fmt == "jpg":
        format_hint = "Opaque image; may export as PNG then convert to JPG on promote."
    else:
        format_hint = f"{fmt.upper()} opaque."
    return "\n".join(
        [
            "Vertiege premium mobile game asset.",
            f"Asset ID: {item['id']}",
            f"Save as: {item['filename']}",
            f"Dimensions: {item['size']} pixels (1:1 square emblem).",
            format_hint,
            item["prompt"].strip(),
            f"Avoid: {item['negativePrompt']}",
            "CRITICAL: No text, letters, numbers, logos, watermarks, or UI chrome.",
        ]
    )


def cmd_status(_: argparse.Namespace) -> None:
    manifest = load_manifest()
    sync_status_from_disk(manifest)
    save_manifest(manifest)
    counts: dict[str, int] = {}
    for item in manifest["items"]:
        counts[item["status"]] = counts.get(item["status"], 0) + 1
    print(f"Image queue: {len(manifest['items'])} items")
    for status, n in sorted(counts.items()):
        print(f"  {status}: {n}")
    nxt = get_next_item(manifest)
    if nxt:
        print(f"\nNext up: {nxt['id']} -> {nxt['stagingPath']}")
    else:
        print("\nQueue complete (no pending/failed).")


def cmd_next(args: argparse.Namespace) -> None:
    manifest = load_manifest()
    sync_status_from_disk(manifest)
    save_manifest(manifest)
    item = get_next_item(manifest)
    if not item:
        payload = {"done": True, "message": "No pending or failed items."}
        print(json.dumps(payload, indent=2) if args.json else payload["message"])
        return
    payload = {
        "done": False,
        "id": item["id"],
        "filename": item["filename"],
        "category": item["category"],
        "format": item["format"],
        "transparent": item["transparent"],
        "size": item["size"],
        "stagingPath": item["stagingPath"],
        "finalPath": item["finalPath"],
        "status": item["status"],
        "prompt": item["prompt"],
        "negativePrompt": item["negativePrompt"],
        "imageDescription": build_chatgpt_prompt(item),
        "agentSteps": [
            f"GenerateImage → save to {item['stagingPath']}",
            f"python3 scripts/image_gen.py mark --id {item['id']} --status generated",
            "Review on dark UI; run process-transparent-assets.sh --staging if matte",
            f"python3 scripts/image_gen.py promote --id {item['id']}",
        ],
    }
    if args.json:
        print(json.dumps(payload, indent=2))
    else:
        print(json.dumps(payload, indent=2))


def cmd_mark(args: argparse.Namespace) -> None:
    manifest = load_manifest()
    item = next((i for i in manifest["items"] if i["id"] == args.id), None)
    if not item:
        raise SystemExit(f"Unknown id: {args.id}")
    item["status"] = args.status
    if args.notes:
        item["notes"] = args.notes
    if args.status == "generated":
        path = staging_file(item)
        if not path.is_file():
            raise SystemExit(f"Missing staging file: {path}")
        item["generatedAt"] = _utc_now()
    if args.status == "approved":
        item["approvedAt"] = _utc_now()
    save_manifest(manifest)
    _append_log(f"{args.id} → {args.status}" + (f" ({args.notes})" if args.notes else ""))
    print(f"Marked {args.id} as {args.status}")


def cmd_promote(args: argparse.Namespace) -> None:
    manifest = load_manifest()
    items = manifest["items"]
    if args.id:
        items = [i for i in items if i["id"] == args.id]
    promoted = 0
    for item in items:
        if item["status"] not in ("generated", "approved"):
            continue
        src = staging_file(item)
        dst = final_file(item)
        if not src.is_file():
            print(f"Skip {item['id']}: no staging file", file=sys.stderr)
            continue
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dst)
        item["status"] = "approved"
        item["approvedAt"] = _utc_now()
        promoted += 1
        print(f"Promoted {item['id']} -> {item['finalPath']}")
    save_manifest(manifest)
    print(f"Promoted {promoted} asset(s).")


def cmd_list(args: argparse.Namespace) -> None:
    manifest = load_manifest()
    for item in manifest["items"]:
        if item["status"] == args.status:
            print(f"{item['id']} [{item['status']}] -> {item['stagingPath']}")


def cmd_copy(args: argparse.Namespace) -> None:
    """Copy an agent-generated file into staging (GenerateImage output path)."""
    manifest = load_manifest()
    item = next((i for i in manifest["items"] if i["id"] == args.id), None)
    if not item:
        raise SystemExit(f"Unknown id: {args.id}")
    src = Path(args.from_path).resolve()
    if not src.is_file():
        raise SystemExit(f"Source not found: {src}")
    dst = staging_file(item)
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src, dst)
    print(f"Copied {src.name} -> {dst}")


def _append_log(line: str) -> None:
    LOG_PATH.parent.mkdir(parents=True, exist_ok=True)
    entry = f"- **{datetime.now().strftime('%Y-%m-%d %H:%M')}** — {line}\n"
    if LOG_PATH.exists():
        LOG_PATH.write_text(LOG_PATH.read_text(encoding="utf-8") + entry, encoding="utf-8")
    else:
        LOG_PATH.write_text(f"# Image generation log\n\n{entry}", encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser(description="Vertiege image generation queue")
    sub = parser.add_subparsers(dest="command", required=True)

    sub.add_parser("status", help="Show queue counts").set_defaults(func=cmd_status)

    p_next = sub.add_parser("next", help="Next pending item (JSON for agents)")
    p_next.add_argument("--json", action="store_true", help="JSON only")
    p_next.set_defaults(func=cmd_next)

    p_mark = sub.add_parser("mark", help="Update item status")
    p_mark.add_argument("--id", required=True)
    p_mark.add_argument(
        "--status",
        required=True,
        choices=["pending", "generated", "approved", "failed", "skipped"],
    )
    p_mark.add_argument("--notes", default=None)
    p_mark.set_defaults(func=cmd_mark)

    p_promote = sub.add_parser("promote", help="Copy staging -> assets/generated")
    p_promote.add_argument("--id", default=None)
    p_promote.add_argument("--all", action="store_true", dest="promote_all")
    p_promote.set_defaults(func=cmd_promote)

    p_list = sub.add_parser("list", help="List items by status")
    p_list.add_argument("--status", default="pending")
    p_list.set_defaults(func=cmd_list)

    p_copy = sub.add_parser("copy", help="Copy generated file into staging")
    p_copy.add_argument("--id", required=True)
    p_copy.add_argument("--from", dest="from_path", required=True)
    p_copy.set_defaults(func=cmd_copy)

    args = parser.parse_args()
    if args.command == "promote" and args.promote_all:
        args.id = None
    args.func(args)


if __name__ == "__main__":
    main()
