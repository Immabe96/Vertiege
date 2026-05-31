# World capability matrix

**Purpose:** Make global tier and world standing legible — players see why a button is locked.

## Global tier (profiles.total_xp)

| Tier | Value | Create dominion | Marketplace listing | Donate treasury |
|------|-------|-----------------|---------------------|-----------------|
| Hustler | 1 | — | — | ✓ |
| High Roller | 2 | ✓ | ✓ | ✓ |
| Elite | 3 | ✓ | ✓ | ✓ |
| Old Money | 4 | ✓ | ✓ | ✓ |
| Apex | 5 | ✓ | ✓ | ✓ |

Enforced in: `WorldCapabilityMatrix`, `AdminAccessService.canCreateWorld`.

## World prestige (feature unlocks)

From `featureUnlocks` in `lib/config/tiers.dart`:

| Prestige | Feature |
|----------|---------|
| 25 | treasury |
| 30 | marketplace |

Dominion worlds also expose marketplace regardless of prestige.

## World standing (rep in one world)

| Standing | Rep | Marketplace list | Treasury withdraw |
|----------|-----|------------------|-------------------|
| Visitor | 0 | — | — |
| Member | 10 | — | — |
| Contributor | 50 | ✓ list | — |
| Council | 5000 | ✓ | ✓ (with sovereign) |

Sovereign bypasses standing checks.

## Code map

| Check | File |
|-------|------|
| Matrix helpers | `lib/config/world_capability_matrix.dart` |
| Post/moderate | `lib/services/permission_service.dart` |
| World growth UI | `lib/widgets/worlds/world_growth_card.dart` |
| Daily quest claim RPC | `supabase/migrations/20260525230000_g3_daily_quests.sql` |
