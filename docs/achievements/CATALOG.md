# Achievement catalog

**Updated:** 2026-05-25

## Sources

| Layer | File | Role |
|-------|------|------|
| Core | `lib/config/achievements.dart` (`_achievementCatalogRaw`) | Hand-authored milestones (~110) |
| Bulk v1 | `lib/config/achievements_bulk_seeds.dart` | First expansion (~200) |
| Bulk v2 | `lib/config/achievements_bulk_seeds_v2.dart` | Extended milestones (`*-ext-*` ids) |
| Proof | `lib/config/achievement_proof_policy.dart` | Category defaults + per-id overrides |

Resolved list: `achievements` = `resolveAchievementCatalog([...])`  
Lookup: `achievementForId(id)` / `achievementById`.

## Categories (13)

`education`, `career`, `relationships`, `health`, `skills`, `travel`, `finance`, `community`, `funny`, `creative`, `life`, `profession`, `inApp`

- **inApp** — auto-granted in app (streaks, pioneer poster); no proof queue.
- **profession** — tied to staff profession verification (`professionToAchievementId`).

## Proof types (4)

`optional`, `required`, `multi`, `location` — see `AchievementProofType` in `lib/models/achievement.dart`.

## Server sync

Postgres `achievement_definitions` must include every catalog id or `grant_verified_achievement` fails.

Regenerate migration after catalog changes:

```bash
python3 scripts/sync_achievement_definitions.py
supabase db push
```

## Product limit

`achievementCatalogLimit = 1000` in `lib/config/achievements.dart`.
