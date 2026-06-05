---
name: vertiege-discord-ux
description: >-
  Vertiege Commune UX — fast chat-native shell with Vertiege lexicon (worlds,
  residents, achievements). Use for DCX-* changes. Borrow layout patterns only;
  never Discord product naming.
---

# Vertiege Commune UX

## Lexicon (mandatory in all UI copy, docs, comments)

| Use | Do not use |
|-----|------------|
| World | server |
| Resident | member |
| Achievement / verified | generic “badge” alone |
| World channel | server channel |
| Nexus | “feed” alone in nav labels |
| Campfire | voice channel (user-facing) |

Achievements, tiers, governance, and economy are **first-class** — not demoted behind chat.

## When to use

- Redesigning navigation, chat, worlds, theme
- Implementing `DCX-xxx` from [discord-redesign-changes.json](../../../docs/product/planning/discord-redesign-changes.json)
- Reviewing UI against [DESIGN.md](../../../docs/reference/DESIGN.md)

## Read first

1. [discord-redesign-master-plan.md](../../../docs/product/planning/discord-redesign-master-plan.md)
2. [vertiege-forui-ui](../vertiege-forui-ui/SKILL.md)

## Non-negotiables

- **Vertiege features stay:** tier gating, worlds, channels, DMs, threads, Campfire, Nexus, achievements, governance, economy, season/league, verifier tools.
- **Borrow patterns, not vocabulary:** panels, hidden nav, dark ladder — not “servers” or “members”.
- **Achievements visible:** Home header, You tab, chat share, unlock toasts — never bury.
- **One primary nav:** bottom tabs + overlapping panels.
- **Hide bottom nav** in world channel, DM, Campfire.
- **URLs stable** unless explicitly approved.

## Key files

| Area | Path |
|------|------|
| Home | `lib/screens/tabs/commune_home_screen.dart` |
| World rail | `lib/ui/navigation/v_world_rail.dart` |
| Panels | `lib/ui/shell/v_overlapping_panels.dart` |
| Tab shell | `lib/screens/tabs/tab_layout.dart` |
| Theme | `lib/theme/v_commune_colors.dart` |

## Smoke test

1. Home → world rail → channel → message (labels say **world**, not server)
2. Achievements reachable from Home and You
3. Tier-locked channel shows lock + tier requirement
4. Bottom nav hidden in channel; returns on back
