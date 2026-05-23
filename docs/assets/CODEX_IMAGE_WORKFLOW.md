# Codex image generation — resumable workflow

Use this when your **daily image limit** resets. Work **one file per session**; progress is saved in the repo so you can stop anytime.

## Where files live (Cursor / git can access these)

| Path | Purpose |
|------|---------|
| `docs/assets/image-manifest.json` | Queue + status + prompts (**commit this after each image**) |
| `assets/staging/generated/` | **New** images land here first (review before ship) |
| `assets/generated/` | Production assets the app loads (promote when happy) |
| `docs/assets/generation-log.md` | Optional human notes per session |

## Before you start (once)

1. Open this repo in Codex with the same root as Vertiege.
2. Read `docs/plan/2026-05-22-image-asset-refresh.md` for art rules:
   - **Banners:** no text, opaque JPG
   - **Badges / prof / ach / tier:** no text, **transparent PNG**
3. Confirm manifest exists: `docs/assets/image-manifest.json`

## Every session (repeat until queue empty)

### Step 1 — Get the next job

```powershell
cd C:\Users\Immabe\Vertiege
.\scripts\image_gen.ps1 next
```

Copy the printed **prompt** and **negative prompt**. Note `stagingPath` — that is where you must save the file.

### Step 2 — Generate exactly one image

- Use ChatGPT Images / DALL·E / your plan’s image tool.
- Match **aspect ratio** and **format** from the manifest (`jpg` vs `png`).
- Save to the **exact** `stagingPath` (e.g. `assets/staging/generated/world-neon-district.jpg`).
- **Do not** add text on banners or badges.

### Step 3 — Mark progress (required)

```powershell
.\scripts\image_gen.ps1 mark -Id world-neon-district -Status generated
```

If generation failed or hit rate limit:

```powershell
.\scripts\image_gen.ps1 mark -Id world-neon-district -Status failed -Notes "daily limit"
```

Status `failed` stays in queue; `next` will skip completed `generated`/`approved` and retry `failed` after `pending`.

### Step 4 — Commit so the next session can resume

```powershell
git add docs/assets/image-manifest.json assets/staging/generated/
git commit -m "assets(staging): generated world-neon-district"
```

When the daily limit hits: **stop after Step 3–4**. Next day, run `next` again — it continues automatically.

### Step 5 — When all items are `generated` (batch review)

```powershell
.\scripts\image_gen.ps1 status
.\scripts\image_gen.ps1 promote -Id world-neon-district   # one file
# or
.\scripts\image_gen.ps1 promote -All                    # copy all generated → assets/generated
.\scripts\validate_assets.ps1
```

CI runs the same check on every PR (`bash scripts/validate_assets.sh` in `.github/workflows/ci.yml`). It fails if:

- Any path in `world_assets.dart` / `cosmetics.dart` is missing on disk
- Any **approved** row in `image-manifest.json` has a `finalPath` that is missing

Unreferenced files in `assets/generated/` (deprecated empty JPGs, legacy tier PNGs) are allowed; use `-StrictUnreferenced` to fail on those locally.

Then mark approved:

```powershell
.\scripts\image_gen.ps1 mark -Id world-neon-district -Status approved
```

## Codex system prompt (paste at start of each chat)

```
You are refreshing Vertiege mobile app images for Immabe96/Vertiege.

Rules:
- Work ONE manifest item per session unless the user says otherwise.
- Read docs/assets/CODEX_IMAGE_WORKFLOW.md and docs/plan/2026-05-22-image-asset-refresh.md.
- Run: .\scripts\image_gen.ps1 next
- Generate the image per prompt; save ONLY to the printed stagingPath (exact filename).
- World banners: JPG, no text/signage/words anywhere.
- badge/prof/ach/tier: PNG with transparent background, emblem only, no text.
- After saving the file, run: .\scripts\image_gen.ps1 mark -Id <id> -Status generated
- Commit image-manifest.json + the new staging file.
- If rate limited, mark failed with Notes and stop; do not skip updating the manifest.
- Never rename files; never write into assets/generated/ until promote.
```

## Status values

| Status | Meaning |
|--------|---------|
| `pending` | Not started |
| `generated` | File exists in `assets/staging/generated/` |
| `approved` | Copied to `assets/generated/`; app-ready |
| `failed` | Blocked (limit, bad output) — retry on next `next` |

## Quick commands

```powershell
.\scripts\image_gen.ps1 status          # counts + next up
.\scripts\image_gen.ps1 next            # print next job (JSON + prompts)
.\scripts\image_gen.ps1 list -Status pending
.\scripts\image_gen.ps1 promote -All    # staging → production
```
