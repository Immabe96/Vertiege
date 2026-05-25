---
name: vertiege-forui-ui
description: >-
  Vertiege-specific UI/UX: Forui 0.21 + VTheme/VColors, AMOLED dark and light
  modes, VHubPage shell, and migration away from Material SnackBar/AppBar sprawl.
  Use when building or auditing Flutter UI in this repo, Forui components,
  theme_provider, or implementing docs/audits/*-ui-ux*.md findings.
---

# Vertiege Forui UI

Project design system for **Vertiege** (tier-gated social app). Read this **with** `flutter-ai-ui-skill` and `ui-design-brain` — those cover general Flutter/web patterns; this skill is the source of truth for **this codebase**.

## Stack (do not contradict)

| Layer | Use |
|-------|-----|
| **Forui** | `FScaffold`, `FHeader`, `FTile`/`FTileGroup`, `FButton`, `FTextField`, `FDialog`, `showFSheet`, `FToaster` |
| **Material** | `ThemeData` via `VTheme` / `AppTheme` — backs Material widgets still in migration |
| **Tokens** | `VSpacing`, `VFontSize`, `VFontWeight` in `lib/theme/v_tokens.dart` |
| **Colors** | Prefer `Theme.of(context).colorScheme` or `context.theme.colors` (Forui); avoid new raw `VColors.*` + `isDark` ternaries |
| **Hub pages** | `VHubPage` (`lib/forui/v_hub_page.dart`) for sub-routes |
| **Settings lists** | `VSectionList` / `VSectionTile` → Forui tiles |

## Theme & light/dark

- User preference: `themeProvider` — `ThemeScheme.system | light | dark` + `TextSize`.
- App wiring: `lib/app.dart` — `MaterialApp.router` + `FTheme(data: VertiegeForuiTheme.light|dark)`.
- **Both** Material `themeMode` and `FTheme` brightness must stay in sync (see `useDarkForui` in `app.dart`).
- Default product look: **AMOLED dark** (violet + gold accents). Light mode must remain fully usable.
- Known gaps (fix when touching related files): splash uses separate dark-only `MaterialApp` (U01); default scheme is light not system (U02).

## Migration rules (new UI)

1. **New screens** → `VHubPage` or `FScaffold` + `FHeader`, not `Scaffold` + `AppBar`.
2. **New buttons** → `FButton`, not `VButton` / `ElevatedButton` (unless inside legacy file not yet migrated).
3. **New inputs** → `FTextField`, not raw `TextField`.
4. **Feedback** → `FToaster` / `showFToast`, not `ScaffoldMessenger.showSnackBar`.
5. **Sheets** → `showFSheet` (`lib/widgets/core/glass_sheet.dart`), not `showModalBottomSheet`.
6. **Confirmations** → `FDialog`, not `AlertDialog`.

## Tab shell (high traffic — Tier A)

These still use Material chrome; align with Forui when editing:

- `lib/screens/tabs/tab_layout.dart`
- `lib/screens/tabs/explore_screen.dart`
- `lib/screens/tabs/nexus_screen.dart`
- `lib/screens/tabs/chat_list_screen.dart`
- ~~`lib/screens/tabs/identity_screen.dart`~~ (uses `VHubPage` — polish feedback only, Tier B)

Reference: `lib/screens/chat_room_screen.dart` (`FScaffold` + `FHeader.nested`).

## Brand constraints

- **Glass / prestige**: `VSurfacePanel`, `glass_panel.dart` — keep tier-gated “luxury” feel; do not flatten to generic SaaS purple gradients.
- **Tier colors**: use `tier_utils` / existing badge widgets; do not invent new tier palettes.
- **Touch targets**: min ~44dp; respect `themeProvider` text scale.

## Audit & verification

- Full UI/UX audit: `docs/audits/2026-05-24-cursor-swarm-ui-ux-audit.md`
- Tracker: `docs/audits/2026-05-24-ui-ux-fix-tracker.md` (U01–U12)
- Re-run swarm: `./scripts/audit-ui-ux.sh`
- Forui widget index: `lib/forui/README.md`
- Analyzer script (flutter-ai-ui-skill): `python .cursor/skills/flutter-ai-ui-skill/scripts/analyse_flutter_project.py`

## Anti-patterns in this repo

- Duplicating `backgroundColor: isDark ? VColors.surfaceDark : VColors.surface` on every `Scaffold` when `ThemeData.scaffoldBackgroundColor` is set.
- Mixing `AppBar` on tab roots with `FHeader` on pushed routes without transition plan.
- Client-only theme flashes (splash / dialogs) that ignore `themeProvider`.
