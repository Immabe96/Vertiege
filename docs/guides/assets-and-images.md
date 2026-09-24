# Codex image generation — resumable workflow

Use this when your **daily image limit** resets. Work **one file per session**; progress is saved in the repo so you can stop anytime.

## Where files live (Cursor / git can access these)

| Path | Purpose |
|------|---------|
| `docs/assets/image-manifest.json` | Queue + status + prompts (**commit this after each image**) |
| `flutter-app/assets/staging/generated/` | **New** images land here first (review before ship) |
| `flutter-app/assets/generated/` | Production assets the app loads (promote when happy) |
| `flutter-app/assets/generated/achievements/` | **Second** production folder — per-id core catalog badges (`<id>.png`) |

Achievement badges use **two production locations**: flat files at `flutter-app/assets/generated/` (category `ach-*.png`, legacy `badge-*` / `prof-*` map) and per-id files at `flutter-app/assets/generated/achievements/`. See [achievements-catalog.md](../reference/achievements-catalog.md) for resolution order.
| `docs/assets/generation-log.md` | Optional human notes per session |

## Cursor agent (GenerateImage)

For Linux/macOS and **Cursor agents** with image generation:

| Piece | Path |
|-------|------|
| Agent definition | `.cursor/agents/vertiege-asset-generator.md` |
| Skill (workflow) | `.cursor/skills/vertiege-asset-generator/SKILL.md` |
| Queue CLI | `python3 flutter-app/scripts/image_gen.py` |
| Enqueue missing `ach-life` / `prof-*` | `python3 flutter-app/scripts/sync_image_manifest.py` |

Example session:

```bash
python3 flutter-app/scripts/sync_image_manifest.py
python3 flutter-app/scripts/image_gen.py next --json
# → use imageDescription with GenerateImage → copy to stagingPath
python3 flutter-app/scripts/image_gen.py mark --id ach-life --status generated
./flutter-app/scripts/process-transparent-assets.sh --staging   # if needed
python3 flutter-app/scripts/image_gen.py promote --id ach-life
```

Invoke in chat: *“Run the Vertiege asset generator agent”* or delegate to subagent **Vertiege Asset Generator**.

## Before you start (once)

1. Open this repo in Codex with the same root as Vertiege.
2. Read [image-asset-refresh plan](../archive/plans/2026-05-22-image-asset-refresh.md) for art rules:
   - **Banners:** no text, opaque JPG
   - **Badges / prof / ach / tier:** no text, **transparent PNG**
3. Confirm manifest exists: `docs/assets/image-manifest.json`

## Every session (repeat until queue empty)

### Step 1 — Get the next job

```powershell
cd C:\Users\Immabe\Vertiege
.\flutter-app\scripts\image_gen.ps1 next
```

Copy the printed **prompt** and **negative prompt**. Note `stagingPath` — that is where you must save the file.

### Step 2 — Generate exactly one image

- Use ChatGPT Images / DALL·E / your plan’s image tool.
- Match **aspect ratio** and **format** from the manifest (`jpg` vs `png`).
- Save to the **exact** `stagingPath` (e.g. `flutter-app/assets/staging/generated/world-neon-district.jpg`).
- **Do not** add text on banners or badges.

### Step 3 — Mark progress (required)

```powershell
.\flutter-app\scripts\image_gen.ps1 mark -Id world-neon-district -Status generated
```

If generation failed or hit rate limit:

```powershell
.\flutter-app\scripts\image_gen.ps1 mark -Id world-neon-district -Status failed -Notes "daily limit"
```

Status `failed` stays in queue; `next` will skip completed `generated`/`approved` and retry `failed` after `pending`.

### Step 4 — Commit so the next session can resume

```powershell
git add docs/assets/image-manifest.json flutter-app/assets/staging/generated/
git commit -m "assets(staging): generated world-neon-district"
```

When the daily limit hits: **stop after Step 3–4**. Next day, run `next` again — it continues automatically.

### Step 4b — Fix matte backgrounds on transparent PNGs (local, no API key)

ChatGPT exports often ship with a light gray/white matte instead of true transparency. Before or after promote, run the local [withoutbg](https://github.com/withoutbg/withoutbg) batch (first run downloads ~320MB of models):

```bash
chmod +x flutter-app/scripts/process-transparent-assets.sh
./flutter-app/scripts/process-transparent-assets.sh --dry-run    # preview list
./flutter-app/scripts/process-transparent-assets.sh              # flutter-app/assets/generated/
# or on staging only:
./flutter-app/scripts/process-transparent-assets.sh --staging
```

Requires **Python 3** and **uv** (`curl -LsSf https://astral.sh/uv/install.sh | sh`). Uses `uvx withoutbg` with the open-source Focus model — no API key.

Originals are backed up under `flutter-app/assets/staging/withoutbg-backup/<timestamp>/`. Review badges on dark UI before committing.

### Step 5 — When all items are `generated` (batch review)

```powershell
.\flutter-app\scripts\image_gen.ps1 status
.\flutter-app\scripts\image_gen.ps1 promote -Id world-neon-district   # one file
# or
.\flutter-app\scripts\image_gen.ps1 promote -All                    # copy all generated → flutter-app/assets/generated
./flutter-app/scripts/process-transparent-assets.sh                 # Linux: fix PNG mattes (optional)
.\flutter-app\scripts\validate_assets.ps1
```

CI runs the same check on every PR (`bash flutter-app/scripts/validate_assets.sh` in `.github/workflows/ci.yml`). It fails if:

- Any path in `world_assets.dart` / `cosmetics.dart` is missing on disk
- Any **approved** row in `image-manifest.json` has a `finalPath` that is missing

Unreferenced files in `flutter-app/assets/generated/` (deprecated empty JPGs, legacy tier PNGs) are allowed; use `-StrictUnreferenced` to fail on those locally.

Then mark approved:

```powershell
.\flutter-app\scripts\image_gen.ps1 mark -Id world-neon-district -Status approved
```

## Codex system prompt (paste at start of each chat)

```
You are refreshing Vertiege mobile app images for Immabe96/Vertiege.

Rules:
- Work ONE manifest item per session unless the user says otherwise.
- Read docs/assets/CODEX_IMAGE_WORKFLOW.md and docs/plan/2026-05-22-image-asset-refresh.md.
- Run: .\flutter-app\scripts\image_gen.ps1 next
- Generate the image per prompt; save ONLY to the printed stagingPath (exact filename).
- World banners: JPG, no text/signage/words anywhere.
- badge/prof/ach/tier: PNG with transparent background, emblem only, no text.
- After saving the file, run: .\flutter-app\scripts\image_gen.ps1 mark -Id <id> -Status generated
- Commit image-manifest.json + the new staging file.
- If rate limited, mark failed with Notes and stop; do not skip updating the manifest.
- Never rename files; never write into flutter-app/assets/generated/ until promote.
```

## Status values

| Status | Meaning |
|--------|---------|
| `pending` | Not started |
| `generated` | File exists in `flutter-app/assets/staging/generated/` |
| `approved` | Copied to `flutter-app/assets/generated/`; app-ready |
| `failed` | Blocked (limit, bad output) — retry on next `next` |

## Quick commands

```powershell
.\flutter-app\scripts\image_gen.ps1 status          # counts + next up
.\flutter-app\scripts\image_gen.ps1 next            # print next job (JSON + prompts)
.\flutter-app\scripts\image_gen.ps1 list -Status pending
.\flutter-app\scripts\image_gen.ps1 promote -All    # staging → production
```
