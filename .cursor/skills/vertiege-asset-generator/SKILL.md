---
name: vertiege-asset-generator
description: >-
  Generate Vertiege game assets (achievement category icons, profession medallions,
  badges) using the image manifest queue and Cursor GenerateImage. Use when the user
  asks to generate achievement images, badge art, asset queue, image-manifest, or
  run the asset generator agent.
---

# Vertiege asset generator

Generate **one image per turn** from `docs/assets/image-manifest.json`. Do not batch 590 per-achievement icons — the app uses **category** PNGs (`ach-education.png`, etc.) plus optional dedicated `prof-*` art.

## Art rules (non-negotiable)

Read `docs/plan/2026-05-22-image-asset-refresh.md` and `docs/assets/CODEX_IMAGE_WORKFLOW.md`.

| Asset | Format | Background |
|-------|--------|------------|
| `ach-*.png`, `prof-*.png`, `badge-*.png`, `tier-*.png` | PNG 512×512 | **Transparent** — no text |
| `world-*.jpg` | JPG 1200×675 | Opaque, no text |

Brand: premium mobile game, violet `#7C3AED` / blue accents, **not** generic gold clipart for every icon.

## Session loop (repeat until queue empty)

### 1. Enqueue missing required assets (once per repo refresh)

```bash
python3 scripts/sync_image_manifest.py
python3 scripts/image_gen.py status
```

### 2. Get next job

```bash
python3 scripts/image_gen.py next --json
```

If `"done": true`, stop and report queue complete.

### 3. Generate with Cursor **GenerateImage**

- Use the JSON field **`imageDescription`** as the full prompt (it already includes negatives).
- **`filename`**: match manifest `filename` (e.g. `ach-life.png`).
- Style: square 1:1 emblem, centered, isolated, readable at 48dp on AMOLED dark UI.

### 4. Copy into staging

GenerateImage saves under the workspace assets path. Copy to the exact **`stagingPath`**:

```bash
python3 scripts/image_gen.py copy --id <id> --from <path-to-generated-png>
```

Or `cp` into `assets/staging/generated/<filename>`.

### 5. Mark and review

```bash
python3 scripts/image_gen.py mark --id <id> --status generated
```

If matte gray background on PNG:

```bash
./scripts/process-transparent-assets.sh --staging
```

### 6. Promote to production

After visual check (dark theme):

```bash
python3 scripts/image_gen.py promote --id <id>
```

Updates `assets/generated/` — **keep filenames**; `lib/utils/world_assets.dart` maps by id.

### 7. Commit progress

```bash
git add docs/assets/image-manifest.json assets/staging/generated/ assets/generated/
git commit -m "assets: generated <id>"
```

## What to generate (priority)

### Phase 1 — Core catalog (do this first) ~104 images

Each **original** achievement in `_achievementCatalogRaw` gets a **unique** badge at:

`assets/generated/achievements/<achievement-id>.png`

Enqueue / refresh prompts:

```bash
python3 scripts/enqueue_core_achievement_badges.py
```

Runtime: `WorldAssets.achievementBadgeImage(id)` → per-id PNG, else category icon, else Material icon.  
`image_gen.py next` prioritizes `achievement_badge` rows before `ach-life` / `prof-*`.

Same finesse as `badge-marathon` / `badge-doctor`: bespoke prompt per title+description, transparent PNG, `process-transparent-assets.sh`.

### Phase 2 — Shared category + profession icons

1. **Missing category icons** — `ach-life`, `ach-profession`
2. **New profession medallions** — `prof-nurse` … `prof-journalist`
3. **Skipped / failed** rows

### Phase 3 — Bulk seeds (later)

**Do not** auto-enqueue 480 bulk seed ids unless product asks; they keep shared `ach-{category}.png` fallbacks.

## Wire-up after new `prof-*` files

When dedicated PNGs exist, point `WorldAssets._badgeImagePaths` in `lib/utils/world_assets.dart` to the new files (not `prof-doctor.png` reuse).

## When all 110 core badges are on disk

```bash
python3 scripts/check_core_achievement_assets.py
./scripts/build_release_apk.sh
```

Output: `build/app/outputs/flutter-apk/app-release.apk`  
CI alternative: GitHub Actions → **Release APK (core assets gate)** (manual).

## Windows

`scripts/image_gen.ps1` remains valid; prefer `scripts/image_gen.py` on Linux/CI.

## Failure handling

```bash
python3 scripts/image_gen.py mark --id <id> --status failed --notes "rate limit"
```

Failed items are retried on the next `next` call.
