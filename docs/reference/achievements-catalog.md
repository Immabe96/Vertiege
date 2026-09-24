# Achievement catalog

**Updated:** 2026-05-25 — **~619** catalog entries (`110` core + bulk v1–v4)

## Sources

| Layer | File | Role |
|-------|------|------|
| Core | `flutter-app/lib/config/achievements.dart` (`_achievementCatalogRaw`) | Hand-authored milestones (~110) |
| Bulk v1 | `flutter-app/lib/config/achievements_bulk_seeds.dart` | First expansion (~200) |
| Bulk v2 | `flutter-app/lib/config/achievements_bulk_seeds_v2.dart` | Extended milestones (`*-ext-*` ids) |
| Bulk v3 | `flutter-app/lib/config/achievements_bulk_seeds_v3.dart` | Third wave (`*-seed-v3-*` ids) |
| Bulk v4 | `flutter-app/lib/config/achievements_bulk_seeds_v4.dart` | Fourth wave (life, travel, funny, community, …) |
| Professions | `flutter-app/lib/config/professions.dart` | Picker list, achievement map, gate worlds |
| Proof | `flutter-app/lib/config/achievement_proof_policy.dart` | Category defaults + per-id overrides |

Resolved list: `achievements` = `resolveAchievementCatalog([...])`  
Lookup: `achievementForId(id)` / `achievementById`.

## Categories (13)

`education`, `career`, `relationships`, `health`, `skills`, `travel`, `finance`, `community`, `funny`, `creative`, `life`, `profession`, `inApp`

- **inApp** — auto-granted in app (streaks, pioneer poster); no proof queue.
- **profession** — tied to staff profession verification (`professionToAchievementId`).

## Proof types (4)

`optional`, `required`, `multi`, `location` — see `AchievementProofType` in `flutter-app/lib/models/achievement.dart`.

## Images — two on-disk locations

Generated achievement art lives in **two places** under `flutter-app/assets/generated/`. The app checks them in order (see `WorldAssets.achievementBadgeImage` in `flutter-app/lib/utils/world_assets.dart`).

| Location | Examples | Used for |
|----------|----------|----------|
| **Flat root** `flutter-app/assets/generated/` | `ach-education.png`, `badge-marathon.png`, `prof-doctor.png` | Legacy id map (`_badgeImagePaths`), **category** emblems for bulk seeds, profession/tier/world assets |
| **Per-id folder** `flutter-app/assets/generated/achievements/` | `achievements/marathon.png`, `achievements/edu-degree.png` | **Core catalog** (~110 ids in `core_achievement_badge_ids.dart`) |

Resolution at runtime (`AchievementBadgeAvatar` via `WorldAssets.achievementEmblemForDisplay`):

**Catalog / not yet verified** (`achievementCatalogEmblem`):

- Non-profession → `flutter-app/assets/generated/ach-<category>.png` (same icon for every achievement in that category)
- Profession → `flutter-app/assets/generated/prof-<role>.png` (unique profession **icon**, not the generic `ach-profession` emblem)

**Verified / earned** (`achievementEarnedEmblem`):

- Non-profession → per-id `flutter-app/assets/generated/achievements/<id>.png` or legacy flat map (unique **badge**)
- Profession → `flutter-app/assets/generated/badge-*.png` medallion (unique **badge**, distinct from the prof icon)

Material icons are fallback only when a PNG fails to load.

**Do not** duplicate paths across both locations for the same id unless intentional (legacy `prof-*` / `badge-*` entries may exist only in the flat map).

| Tier | Count | Primary asset path | Look |
|------|------:|-------------------|------|
| **Core** | ~110 | `flutter-app/assets/generated/achievements/<id>.png` | Unique badge per milestone |
| **Bulk seeds** | ~509 | `flutter-app/assets/generated/ach-<category>.png` | Shared category emblem (flat root) |
| **Profession** | 14 | `flutter-app/assets/generated/prof-*.png` or legacy `badge-*` map | Verified profession medallions (flat root) |

**Staging** (not loaded by the app): `flutter-app/assets/staging/generated/` — promote into one of the two production locations above (`docs/assets/CODEX_IMAGE_WORKFLOW.md`).

Enqueue core badges: `python3 flutter-app/scripts/enqueue_core_achievement_badges.py`  
Verify core PNGs: `python3 flutter-app/scripts/check_core_achievement_assets.py`  
Generate: Cursor agent **Vertiege Asset Generator** (`docs/assets/CODEX_IMAGE_WORKFLOW.md`).

## Server sync

Postgres `achievement_definitions` must include every catalog id or `grant_verified_achievement` fails.

Regenerate migration after catalog changes:

```bash
python3 flutter-app/scripts/sync_achievement_definitions.py
supabase db push
```

## Product limit

`achievementCatalogLimit = 1000` in `flutter-app/lib/config/achievements.dart`.
