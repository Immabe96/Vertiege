# Vertiege Commune Design System

**Status:** Wave 2 — Commune theme tokens + presets  
**Lexicon:** worlds · residents · achievements · tiers (see [archived master plan](../archive/planning/discord-redesign-master-plan.md) · active [PLAN.md](../../PLAN.md))

We adopt **chat-native layout patterns** (panel navigation, dark ladder, immersive channels). We do **not** adopt another product's vocabulary.

---

## Philosophy

- **Chat-first shell, Vertiege soul:** fast paths to world channels and DMs; achievements and tiers stay visible.
- **Dark ladder:** depth via surface lightness, not shadows.
- **Accent discipline:** gold/violet on CTAs, mentions, active nav, tier locks — never on list/chat backgrounds.
- **Commune default:** new installs use the Commune preset; Prestige Noir remains optional in Settings.

---

## Color — Commune ladder

`lib/theme/v_commune_colors.dart`

### Dark

| Token | Hex | Use |
|-------|-----|-----|
| `surfacePrimary` | `#313338` | Chat background |
| `surfaceSecondary` | `#2b2d31` | Channel list, cards |
| `surfaceSecondaryAlt` | `#232428` | Elevated rows |
| `surfaceTertiary` | `#1e1f22` | World rail, composer |
| `surfaceFloating` | `#111214` | Modals, tooltips |
| `textNormal` | `#dbdee1` | Message body |
| `textMuted` | `#949ba4` | Timestamps, hints |
| `headerPrimary` | `#f2f3f5` | Resident names, titles |
| `textLink` | `#00a8fc` | URLs |
| `textMention` | brand gold | @mentions |
| `dividerSubtle` | 10% white | 1px separators |

### Light (DCX-041)

| Token | Hex |
|-------|-----|
| `surfacePrimaryLight` | `#ffffff` |
| `surfaceSecondaryLight` | `#f2f3f5` |
| `textNormalLight` | `#313338` |
| `textLinkLight` | `#006ce7` |

### Status (DCX-033)

| State | Hex |
|-------|-----|
| Online | `#23a55a` |
| Idle | `#f0b232` |
| DND | `#f23f43` |
| Offline | `#80848e` |

Use `presenceColor()` from `lib/utils/presence_utils.dart`.

### Prestige accents

`VColors.brand`, `VColors.secondary` — achievements, tier gates, primary buttons only.

---

## Typography — chat roles (DCX-027)

`VFonts.chat(role: …)` with `VChatTextRole`:

- `normal` — message body
- `muted` — timestamps
- `headerPrimary` — display names
- `link` / `mention` — inline chat highlights

---

## Radii & density (DCX-029, DCX-038)

| Token | Value | Use |
|-------|-------|-----|
| `VRadius.communeCard` | 8px | Cards, panels |
| `VRadius.communeButton` | pill | Buttons, chips |
| `VIconSize.denseLg/Md/Sm` | 20/16/14 | Channel rows |

---

## Elevation (DCX-031)

`VSurfaceCard(elevation: …)` maps to surface ladder — **no drop shadows**.

---

## Theme presets (DCX-035)

| Preset | Material | Forui |
|--------|----------|-------|
| Commune (default) | `VTheme.darkCommune` / `lightCommune` | `VertiegeForuiTheme.darkCommune` |
| Prestige | `VTheme.dark` / `light` | `VertiegeForuiTheme.dark` |

Picker: `VThemeSchemePicker` in Settings → Appearance.

### Accessibility (DCX-036)

Saturation and contrast sliders (0.5–1.5) in Settings; applied via `ColorFiltered` in `app.dart`.

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
| `VMessageBubble` | `lib/widgets/chat/v_message_bubble.dart` |
| `VCommuneChatTheme` | `lib/theme/v_commune_chat_theme.dart` |
| `VSurfaceCard` | `lib/ui/cards/v_surface_card.dart` |

Chat chrome uses **solid** surfaces (`useCommuneStyle: true` on composers); glass blur only on modals.

---

## Assets

[discord-redesign-asset-manifest.json](../assets/discord-redesign-asset-manifest.json) — paths use `world_*` naming, not `server_*`.
