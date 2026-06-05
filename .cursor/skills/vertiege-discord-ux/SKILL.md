---
name: vertiege-discord-ux
description: >-
  Vertiege Commune UX redesign — Discord++ mobile patterns with tier/achievement
  differentiators. Use when redesigning navigation, chat, worlds, theme, or
  implementing DCX-* changes from discord-redesign-changes.json.
---

# Vertiege Commune UX (Discord++)

## When to use

- Redesigning screens, navigation, chat, or theme for Discord-like UX
- Implementing a change ID (`DCX-xxx`) from the changes database
- Adding assets (`DRA-xxx`) from the asset manifest
- Reviewing whether a UI pattern matches Commune spec

## Read first

1. [discord-redesign-master-plan.md](../../../docs/product/planning/discord-redesign-master-plan.md)
2. [discord-redesign-changes.json](../../../docs/product/planning/discord-redesign-changes.json) — find your `DCX-*` item
3. [DESIGN.md](../../../docs/reference/DESIGN.md) — Commune color/type rules
4. [vertiege-forui-ui](../vertiege-forui-ui/SKILL.md) — wrapper rules (no direct `forui` in screens)

## Non-negotiables

- **Preserve core features:** tier gating, worlds, channels, DMs, threads, Campfire, Nexus feed, achievements, governance, economy, season/league, verifier tools.
- **One primary navigation:** bottom tabs only; panels for Home hierarchy.
- **Hide bottom nav** inside active channel/DM (Discord pattern).
- **Chat surfaces:** neutral dark ladder — no gold glass on message areas.
- **Accent discipline:** gold/violet for CTAs, mentions, tier locks — not list backgrounds.
- **URLs stable:** `go_router` paths unchanged; panel state is UI-only unless explicitly approved.

## Implementation order

1. Theme tokens (`VCommuneColors`) before screen rewrites
2. `VOverlappingPanels` + server rail before collapsing tabs
3. Extract `VMessageBubble` before polishing channel/DM screens
4. Update change `status` to `done` in JSON when shipped

## Key files

| Area | Path |
|------|------|
| Tab shell | `lib/screens/tabs/tab_layout.dart` |
| Router | `lib/router/app_router.dart` |
| Chat list | `lib/screens/tabs/chat_list_screen.dart` |
| World channel | `lib/screens/world_channel_screen.dart` |
| DM room | `lib/screens/chat_room_screen.dart` |
| Theme | `lib/theme/v_commune_colors.dart`, `lib/theme/v_colors.dart` |
| Panels (new) | `lib/ui/shell/v_overlapping_panels.dart` |
| Server rail (new) | `lib/ui/navigation/v_server_rail.dart` |
| Message bubble (new) | `lib/widgets/chat/v_message_bubble.dart` |

## Discord reference tokens (map to Vertiege)

| Discord | Commune token |
|---------|---------------|
| `#313338` background-primary | `VCommuneColors.surfacePrimary` |
| `#2b2d31` background-secondary | `VCommuneColors.surfaceSecondary` |
| `#1e1f22` background-tertiary | `VCommuneColors.surfaceTertiary` |
| `#dbdee1` text-normal | `VCommuneColors.textNormal` |
| `#949ba4` text-muted | `VCommuneColors.textMuted` |
| Brand accent | `VColors.brand` (gold) — interactive only |

## Asset workflow

1. Pick `DRA-xxx` from `docs/assets/discord-redesign-asset-manifest.json`
2. Generate → place at `path` in manifest
3. Run `bash scripts/validate_discord_redesign_assets.sh`
4. Set `"status": "approved"` in manifest

## Smoke test after each wave

1. Cold start → Home panels visible
2. Tap world → channel list → message send
3. DM from profile → no white screen
4. Back restores bottom nav
5. You tab → achievements + settings reachable
6. Tier-locked channel shows lock, not hidden route
