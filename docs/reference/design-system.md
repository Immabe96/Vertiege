# Design system reference

> **Commune UX redesign:** [DESIGN.md](DESIGN.md) · [archived master plan](../archive/planning/discord-redesign-master-plan.md) · Vertiege lexicon (worlds, residents, achievements) · 144 tracked changes (archived).

> **Status: Current** — Prestige Noir + Forui (2026).  
> **Migration:** [shadcn-migration-plan.md](../archive/planning/shadcn-migration-plan.md) (archived) — Wave 0 chose **Forui 0.21**; wrapper consolidation (not shadcn swap).  
> Historical glassmorphism spec: [archive/design-sovereign-excellence-historical.md](../archive/design-sovereign-excellence-historical.md).

## Stack

- **Material 3** — `ThemeData` via `lib/theme/v_theme.dart` (dark-only)
- **Forui** — `FScaffold`, `FHeader`, `FBottomNavigationBar`, forms, sheets (`forui: ^0.21.3`)
- **Tokens** — `lib/theme/prestige_noir.dart`, `v_colors.dart`, `v_tokens.dart`, `v_context_colors.dart`
- **Forui theme** — `lib/theme/forui_theme.dart` (`VertiegeForuiTheme.dark` — sole theme)

## Themes

| Mode | Surfaces | Notes |
|------|----------|--------|
| **Dark (only)** | Prestige Noir (`PrestigeNoir.bg` / `surface` / `surfaceRaised`) | Cool-tinted charcoal; gold accent discipline |

App is locked to `ThemeMode.dark` in `lib/state/theme_provider.dart`. `VTheme.light` / `VertiegeForuiTheme.light` are legacy aliases that resolve to dark.

App shell: `FTheme` → `FToaster` → `FTooltipGroup` → `Material` → content (`lib/app.dart`).

## Brand colors (summary)

| Token | Role |
|-------|------|
| `PrestigeNoir.accent` / `VColors.brand` | Prestige gold — CTAs, Campfire, splash |
| `VColors.primary` | Violet — worlds, links |
| Tier palette | `tierHustler` … `tierApex` — resident progression |
| Achievement palette | `achievementEducation` … — category accents |

Use `context.vOnSurface`, `context.vPrimary`, etc. from `v_context_colors.dart` instead of hard-coded light/dark pairs. **Do not** add `isDark ?` ternaries.

## Typography

- **Sans:** Plus Jakarta Sans (`VFonts.sansFamily`, `lib/theme/v_fonts.dart`)
- **Mono:** JetBrains Mono — codes, technical labels
- Sizes/weights: `VFontSize`, `VFontWeight` in `v_tokens.dart` — aligned with `VertiegeForuiTheme` type scale

## Layout & motion

- Spacing: `VSpacing` (xxs → xxxl)
- Radius: `VRadius.bento` / `VRadius.lg` (both **14** — single card radius)
- Motion: `VAnimation` durations + `context.motionDuration()` for reduced-motion respect
- Touch: `VTouchTarget.minimum` (48dp) for primary taps — enforced on `VButton`

## Card primitives

| Widget | Role |
|--------|------|
| `VCard` | Flat Prestige Noir surface (`VSurfaceElevation` ladder) |
| `VPrestigeCard` | Raised bento / hero cards (optional gradient, border overrides) |

Legacy `VSurfaceCard`, `GlassPanel`, `SovereignCard`, `PrestigeRaisedCard` are removed — use the two primitives above.

## Feedback & loading

| Widget | Role |
|--------|------|
| `VSpinner` | Inline progress (replaces raw `CircularProgressIndicator` in feature code) |
| `VLoadingState` / `VEmptyState` / `VErrorState` | Full-area states |
| `VFeedback` | Toasts (not `SnackBar`) |
| `showVDialog` | Dialogs (not raw `AlertDialog`) |

## UI conventions

1. **Tab screens** — `VTabShell` (`lib/ui/shell/v_tab_shell.dart`) — Forui `FScaffold` + `FHeader` inside.
2. **Hub sub-pages** — `VPage` (`lib/ui/shell/v_page.dart`).
3. **Import path** — feature screens use `package:vertiege/ui/ui.dart`; **no** `import 'package:forui/forui.dart'` in `lib/screens/`. Forui stays inside `lib/ui/` wrappers.
4. **Buttons** — `VButton` / `VIconButton` in feature code; `VGateCta` for auth gate gold CTAs only.
5. **Wide panels** — use `VCard` + full width, not `FTile.raw` with `Expanded` rows.
6. See [lib/forui/README.md](../../lib/forui/README.md).

## Prestige Noir direction

Tier-gated social worlds — UI should feel **premium, calm, and legible**.

| Token | Role |
|-------|------|
| `PrestigeNoir.bg` | App background |
| `PrestigeNoir.surface` / `surfaceRaised` | Cards and panels |
| `PrestigeNoir.foreground` / `muted` | Text hierarchy |
| `PrestigeNoir.accent` | Gold — sparingly for CTAs and progression |

Dark base `#101114` with stepped surfaces — avoid pure `#000000` for long reading. No drop shadows on cards (elevation via surface lightness).

## Cross-platform UI rules

1. One Flutter UI — no separate Cupertino shell.
2. Prefer `VButton`, `VTile` / `VSectionTile`, theme text styles over ad-hoc `Material` + `InkWell`.
3. Motion: `context.motionDuration()` / `VHaptics` (reduced motion).
4. Full-screen routes: `vGoRoute` in `app_router.dart`.
5. Auth: `AuthSocialButtons` — Apple on iOS/macOS; Google on mobile.
6. Empty states: `AppEmptyState` + `assets/images/empty_states/`.
7. Remote tuning: Firebase `forui_strict_mode`, `minimum_build` (+ optional per-platform keys).

## Related docs

- [guides/assets-and-images.md](../guides/assets-and-images.md) — badge & illustration pipeline
- [achievements-catalog.md](achievements-catalog.md) — achievement assets
- [../audits/2026-06-29-release-readiness-audit.md](../audits/2026-06-29-release-readiness-audit.md) — latest UI/UX audit
- [../archive/design-sovereign-excellence-historical.md](../archive/design-sovereign-excellence-historical.md) — pre-Forui glass spec
