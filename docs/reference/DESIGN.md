# Vertiege Commune Design System

**Codename:** Commune UX (Discord++ with Vertiege progression)  
**Status:** Wave 0 — tokens landed; screens not yet migrated  
**Changes:** [discord-redesign-changes.json](../product/planning/discord-redesign-changes.json) (144 items)

---

## Philosophy

- **Chat-first:** Conversations are the hero; progression accents the edges.
- **Dark ladder:** Depth via surface lightness, not shadows.
- **One primary nav:** Bottom tabs + overlapping panels — never drawer + tabs.
- **Vertiege wins on stakes:** Tiers, achievements, governance visible but not noisy.

---

## Color — Commune ladder

Implemented in `lib/theme/v_commune_colors.dart`.

| Token | Hex | Use |
|-------|-----|-----|
| `surfacePrimary` | `#313338` | Chat background, main content |
| `surfaceSecondary` | `#2b2d31` | Channel list, side panels |
| `surfaceSecondaryAlt` | `#232428` | Row hover |
| `surfaceTertiary` | `#1e1f22` | Server rail, inputs |
| `surfaceFloating` | `#111214` | Modals, popouts |
| `textNormal` | `#dbdee1` | Message body |
| `textMuted` | `#949ba4` | Timestamps, metadata |
| `headerPrimary` | `#f2f3f5` | Usernames, titles |
| `textLink` | `#00a8fc` | URLs |

**Brand (Vertiege gold / violet):** `VColors.brand`, `VColors.secondary` — buttons, mentions, tier locks, achievement moments. **Not** chat list backgrounds.

**Modifiers:** `modifierHover` / `modifierActive` / `modifierSelected` on list rows.

---

## Typography

| Role | Style |
|------|--------|
| Channel name | `titleSmall`, semiBold, `headerPrimary` |
| Message author | `labelLarge`, semiBold, `headerPrimary` |
| Message body | `bodyMedium`, `textNormal` |
| Timestamp | `labelSmall`, `textMuted` |
| Section header | `labelSmall`, bold, uppercase, `textMuted` |

---

## Layout

```
┌────┬──────────┬─────────────────────┐
│Rail│ Channels │ Chat / Feed         │
│48dp│ 240dp    │ flex                │
└────┴──────────┴─────────────────────┘
        ↑ OverlappingPanels on phone
```

- **Phone:** Rail collapses to icons; channels slide over; chat full-screen hides bottom nav.
- **Tablet:** Three columns persistent.

---

## Components (target)

| Component | File | Status |
|-----------|------|--------|
| `VOverlappingPanels` | `lib/ui/shell/v_overlapping_panels.dart` | planned |
| `VServerRail` | `lib/ui/navigation/v_server_rail.dart` | planned |
| `VChannelTile` | `lib/ui/lists/v_channel_tile.dart` | planned |
| `VMessageBubble` | `lib/widgets/chat/v_message_bubble.dart` | planned |
| `VMessageGrouper` | existing `chat_message_grouper.dart` | migrate |

---

## Motion

- Panel open/close: **300ms**, `Curves.easeOutCubic` (Material guideline)
- No physics fling on panels (Discord Android lesson)
- Respect `MediaQuery.disableAnimations` / reduce motion setting

---

## Assets

See [discord-redesign-asset-manifest.json](../assets/discord-redesign-asset-manifest.json) — 50 tracked assets (`DRA-001` … `DRA-050`).

Validate: `bash scripts/validate_discord_redesign_assets.sh`
