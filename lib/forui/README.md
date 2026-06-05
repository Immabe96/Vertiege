# Forui wrappers (Vertiege)

Vertiege uses **[Forui](https://forui.dev)** (`forui: ^0.21.3`) behind **`V*` facades** in `lib/ui/`.

Wave 0 (2026-06-05): **Forui baseline kept** — wrapper consolidation, not library swap.

## Public shell API

| Type | File | Backing |
|------|------|---------|
| `VPage` | `lib/ui/shell/v_page.dart` | `FScaffold` + `FHeader` |
| `VTabShell` | `lib/ui/shell/v_tab_shell.dart` | `FScaffold` + `FHeader` |

Legacy names `VHubPage` / `VTabPage` are typedefs — prefer `VPage` / `VTabShell`.

Import: `package:vertiege/ui/ui.dart` or `lib/ui/shell/*.dart`.

## Forui primitives (inside wrappers only)

| Area | Widgets |
|------|---------|
| Layout | `FScaffold`, `FHeader`, `FHeader.nested`, `FHeaderAction` |
| Navigation | `FTabs`, `FBottomNavigationBar` |
| Lists | `VSectionList`, `VTile` — `lib/ui/lists/v_section_list.dart` |
| Forms | `FButton`, `FSelect`, `FSwitch`, `FTextField` |
| Feedback | `FDialog`, `FSheet`, `FToast` |

Theme: `lib/theme/forui_theme.dart` → `FTheme` in `app.dart`.

## Layout rules

- **Do not** put `Expanded` / full-width `Row` children inside `FTile.raw` — use a `Card` with bounded width (Settings Appearance pattern).
- Feature screens: **no** `import 'package:forui/forui.dart'` — use `lib/ui/*` and `VSectionList`.
