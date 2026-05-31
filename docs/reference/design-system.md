# Design system reference

> **Status: Current** — Prestige Noir + Forui (2026).  
> Historical glassmorphism spec: [archive/design-sovereign-excellence-historical.md](../archive/design-sovereign-excellence-historical.md).

## Stack

- **Material 3** — `ThemeData` via `lib/theme/app_theme.dart`
- **Forui** — `FScaffold`, `FHeader`, `FBottomNavigationBar`, forms, sheets (`forui: ^0.21.3`)
- **Tokens** — `lib/theme/v_colors.dart`, `v_tokens.dart`, `v_context_colors.dart`
- **Forui theme** — `lib/theme/forui_theme.dart` (`VertiegeForuiTheme.light` / `.dark`)

## Themes

| Mode | Surfaces | Notes |
|------|----------|--------|
| Light | White / soft containers | Default readable text on light surfaces |
| Dark | Charcoal hierarchy (`VColors.surfaceDark`…) | Prestige Noir — not pure AMOLED black |

App shell: `FTheme` → `FToaster` → `FTooltipGroup` → `Material` → content (`lib/app.dart`).

## Brand colors (summary)

| Token | Role |
|-------|------|
| `VColors.primary` | Deep violet — primary actions |
| `VColors.tertiary` / brand gold | Prestige highlights, Campfire |
| Tier palette | `tierHustler` … `tierApex` — resident progression |
| Prestige world | `prestigeBronze` … `prestigeApex` |

Use `context.vOnSurface`, `context.vPrimary`, etc. from `v_context_colors.dart` instead of hard-coded light/dark pairs.

## Typography

- **Sans:** Plus Jakarta Sans (`VFont.sans`, `lib/theme/v_fonts.dart`)
- **Mono:** JetBrains Mono — codes, technical labels
- Sizes/weights: `VFontSize`, `VFontWeight` in `v_tokens.dart`

## Layout & motion

- Spacing: `VSpacing` (xxs → xxxl)
- Radius: `VRadius`
- Motion: `VAnimation` durations + `context.motionDuration()` for reduced-motion respect
- Touch: `VTouchTarget.minimum` (48dp) for primary taps

## UI conventions

1. **Tab screens** — `VTabPage` / `FScaffold` + `FHeader` (`lib/forui/v_tab_page.dart`).
2. **Hub sub-pages** — `VHubPage` pattern (`lib/forui/v_hub_page.dart`).
3. **Ink / tooltips** — ensure a `Material` ancestor (`Material(transparency)` on tab bodies).
4. **Prefer Forui** over raw `Scaffold` / `ListTile` on new screens — see [lib/forui/README.md](../../lib/forui/README.md).

## Prestige Noir direction

Tier-gated social worlds — UI should feel **premium, calm, and legible**.

| Token | Role |
|-------|------|
| `VColors.primary` | Neutral chrome |
| `VColors.brand` / `tertiary` | Prestige gold — CTAs, Campfire, splash |
| `VColors.secondary` | Violet — worlds |
| `VColors.link` / `linkDark` | URLs only (not `tertiary`) |

Dark base surface `#0F1117` with stepped containers — avoid pure `#000000` for long reading.

## Cross-platform UI rules

1. One Flutter UI — no separate Cupertino shell.
2. Prefer `VButton`, `FTile`, theme text styles over ad-hoc `Material` + `InkWell`.
3. Motion: `context.motionDuration()` / `VHaptics` (reduced motion).
4. Full-screen routes: `vGoRoute` in `app_router.dart`.
5. Auth: `AuthSocialButtons` — Apple on iOS/macOS; Google on mobile.
6. Empty states: `AppEmptyState` + `assets/images/empty_states/`.
7. Remote tuning: Firebase `forui_strict_mode`, `minimum_build` (+ optional per-platform keys).

## Related docs

- [guides/assets-and-images.md](../guides/assets-and-images.md) — badge & illustration pipeline
- [achievements-catalog.md](achievements-catalog.md) — achievement assets
- [../archive/design-sovereign-excellence-historical.md](../archive/design-sovereign-excellence-historical.md) — pre-Forui glass spec
