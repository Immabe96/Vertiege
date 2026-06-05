# Vertiege Commune Design System

**Status:** Wave 1 — tokens + Home shell  
**Lexicon:** worlds · residents · achievements · tiers (see [master plan](../product/planning/discord-redesign-master-plan.md))

We adopt **chat-native layout patterns** (panel navigation, dark ladder, immersive channels). We do **not** adopt another product’s vocabulary.

---

## Philosophy

- **Chat-first shell, Vertiege soul:** fast paths to world channels and DMs; achievements and tiers stay visible.
- **Dark ladder:** depth via surface lightness, not shadows.
- **Prestige accents:** gold/violet on achievements, tier gates, CTAs — not on message list backgrounds.

---

## Color — Commune ladder

`lib/theme/v_commune_colors.dart`

| Token | Hex | Use |
|-------|-----|-----|
| `surfacePrimary` | `#313338` | Chat background |
| `surfaceSecondary` | `#2b2d31` | Channel list |
| `surfaceTertiary` | `#1e1f22` | **World rail**, inputs |
| `textNormal` | `#dbdee1` | Message body |
| `headerPrimary` | `#f2f3f5` | Resident names, titles |

Brand: `VColors.brand`, `VColors.tertiary` — achievements, tier locks, primary actions.

---

## Layout

```
┌────┬──────────┬─────────────────────┐
│World│ Channels │ Chat / Nexus       │
│rail │ list     │ content             │
└────┴──────────┴─────────────────────┘
```

---

## Components

| Component | File |
|-----------|------|
| `VOverlappingPanels` | `lib/ui/shell/v_overlapping_panels.dart` |
| `VWorldRail` | `lib/ui/navigation/v_world_rail.dart` |
| `VChannelTile` | `lib/ui/lists/v_channel_tile.dart` |
| `VMessageBubble` | planned `lib/widgets/chat/v_message_bubble.dart` |

---

## Assets

[discord-redesign-asset-manifest.json](../assets/discord-redesign-asset-manifest.json) — paths use `world_*` naming, not `server_*`.
