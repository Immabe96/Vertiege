# UI widget mapping — Forui → candidates

**Companion to:** [shadcn-migration-plan.md](shadcn-migration-plan.md)  
**Baseline:** Forui `0.21.3` · snapshot 2026-05-30

This doc maps **actual Vertiege usage** (not theoretical parity) to `shadcn_ui`, `shadcn_flutter`, and Material 3. Wave 0 scores each row on the spike device.

---

## Usage summary (Forui symbols in `lib/`)

| Forui symbol | Files (approx.) | Vertiege role |
|--------------|-----------------|---------------|
| `FScaffold` / `FHeader` / `FHeaderAction` | 15+ | Tab + hub + world/chat shells |
| `FBottomNavigationBar` | 1 (`tab_layout.dart`) | Five-tab root chrome |
| `FTile` / `FTileGroup` / `FTileMixin` | 8 | Settings (`VSectionList`), dossier, achievements |
| `FButton` | 15+ | Via `VButton` + inline CTAs |
| `FCard` | 18+ | Feed cards, shop, dossier sections |
| `FDialog` / `showFDialog` | 8 | Confirm, permissions, tier/prestige |
| `FSheet` / `showFSheet` | 1 (`glass_sheet.dart`) | Bottom sheets (side `FLayout.btt`) |
| `FTabs` / `FTabEntry` | 4 | Shop, hall, verifier, discovery |
| `FSelect` | 5 | Settings text size, world forms, academy |
| `FSwitch` | 2 | Settings toggles, create-world |
| `FTextFormField` | 1 (`create_world_screen`) | Managed text fields |
| `FAlert` | 2 | Dossier info banners |
| `FToaster` / `showFToast` | 2 (`app.dart`, `v_feedback.dart`) | Toasts with action button |
| `FCircularProgress` | 8 | Loading states |
| `FTheme` / `FColors` | 2 (`app.dart`, `forui_theme.dart`) | Global theme bridge |
| `FIcons` | 24 | Chevron, bell, search, lock, etc. |
| `FTooltipGroup` | 1 (`app.dart`) | Tooltip ancestor |
| `FLocalizations` | 1 (`app.dart`) | Locale delegates |

**Implication:** Shell (`FScaffold` + bottom nav) and theme root are the highest-risk migrations. Leaf widgets (button, card, dialog) are mostly behind existing `V*` facades.

---

## Mapping table

| Vertiege / Forui | `shadcn_ui` (primary) | `shadcn_flutter` (fallback) | Material 3 (Plan C) | Gap |
|------------------|----------------------|----------------------------|---------------------|-----|
| `VHubPage` → `FScaffold`+`FHeader` | **Custom `VPage`**: `Scaffold` + `AppBar` or sliver header styled with `ShadTheme` | `Scaffold(headers: [AppBar(...)])` | `Scaffold` + `AppBar` | **High** — no first-class page scaffold in `shadcn_ui` |
| `VTabPage` / `FBottomNavigationBar` | `NavigationBar` (M3) inside `VTabShell`; theme from `ShadTheme.of` | `Scaffold(footers: [NavigationBar(...)])` | `NavigationBar` | **Medium** for `shadcn_ui` — bottom nav is M3 |
| `VSectionTile` → `FTile` | Custom row: `ShadButton.ghost` or `ListTile` + `ShadTheme` text styles | `OutlineButton` list rows or `Card` sections | `ListTile` | **Medium** — no direct settings-row primitive |
| `VButton` → `FButton` | `ShadButton` (+ variants) | `PrimaryButton`, `OutlineButton`, … | `FilledButton` / `OutlinedButton` | **Low** — already facaded |
| `FCard` / `VSurfaceCard` | `ShadCard` | `Card` | `Card` | **Low** |
| `showVDialog` → `showFDialog` | `showShadDialog` + `ShadDialog` | `showDialog` + `Dialog` | `showDialog` + `AlertDialog` | **Low** |
| `glass_sheet` → `FSheet` | `ShadSheet` / sheet overlay APIs | `openSheet(position: bottom)` | `showModalBottomSheet` | **Low–Med** — spike side sheets |
| `FTabs` (in-screen) | `ShadTabs` | `Tabs` / `TabList` + `TabPane` | `TabBar` + `TabBarView` | **Low** |
| `FSelect` | `ShadSelect` | `Select` / `MultiSelect` | `DropdownMenu` | **Med** — rich selects in settings |
| `FSwitch` | `ShadSwitch` | `Switch` | `Switch` | **Low** |
| `FTextFormField` | `ShadInput` + `ShadForm` | `TextField` | `TextFormField` | **Low** (single screen) |
| `FAlert` | `ShadAlert` | `Alert` | `MaterialBanner` / custom | **Low** |
| `VFeedback` → `showFToast` | `ShadToast` | Package toast helper | `SnackBar` | **Med** — action toasts |
| `FCircularProgress` | `ShadProgress` (or M3 spinner) | `CircularProgressIndicator` | `CircularProgressIndicator` | **Low** |
| `VertiegeForuiTheme` / `FTheme` | `ShadThemeData` + `ShadApp.custom` wrapping existing `MaterialApp` | shadcn_flutter theme on `Scaffold` | `ThemeData` + `ColorScheme.fromSeed` | **High** — full token map required |
| `FIcons.*` | `LucideIcons` (package) or Material `Icons` | shadcn_flutter icon set | `Icons.*` | **Med** — 24 files; batch replace |
| `FTooltipGroup` | `ShadTooltip` per widget or M3 `Tooltip` | `Tooltip` | `Tooltip` | **Low** |
| `FLocalizations` | `GlobalShadLocalizations.delegate` | Package l10n | Flutter delegates only | **Med** — verify locale list |

---

## Theme token bridge (`VertiegeForuiTheme` → `ShadThemeData`)

Map existing `VColors` into `ShadColorScheme` (custom scheme based on `ShadZincColorScheme` or `ShadVioletColorScheme`):

| `FColors` / Vertiege | `ShadColorScheme` field | Source token |
|----------------------|-------------------------|--------------|
| `background` | `background` | `VColors.surface` / `surfaceDark` |
| `foreground` | `foreground` | `VColors.onSurface` / `onSurfaceDark` |
| `primary` | `primary` | `VColors.primary` / `primaryLight` |
| `primaryForeground` | `primaryForeground` | `VColors.onPrimary` / `primaryDark` |
| `secondary` | `secondary` | `VColors.surfaceContainerLow` |
| `muted` | `muted` | `VColors.surfaceContainer` |
| `mutedForeground` | `mutedForeground` | `VColors.onSurfaceVariant` |
| `destructive` | `destructive` | `VColors.error` |
| `card` | `card` | `VColors.surfaceContainerLowest` |
| `border` | `border` | `VColors.outlineVariant` |

Typography: map `FTypography` scale → `ShadThemeData.textTheme` using `VFonts.sansFamily` (Plus Jakarta Sans via `google_fonts`).

**`app.dart` target shape (hybrid, routes unchanged):**

```dart
// Wave A sketch — not implemented until Wave 0 passes
ShadApp.custom(
  themeMode: themeMode,
  theme: VertiegeShadTheme.light,
  darkTheme: VertiegeShadTheme.dark,
  appBuilder: (context) => MaterialApp.router(
    // existing router, delegates, MediaQuery textScaler…
    builder: (context, child) => ShadAppBuilder(child: child!),
  ),
);
```

Replace `_withForui` (`FTheme` → `FToaster` → `FTooltipGroup` → `Material`) with the above + `VFeedback` backed by `ShadToast`.

---

## Package comparison (Vertiege-specific)

| Dimension | `shadcn_ui` | `shadcn_flutter` |
|-----------|-------------|------------------|
| License | MIT | BSD-3-Clause |
| Maturity / docs | Strong; mariuti.com docs + Agent Skills | Broad widget catalog (84+); heavier API surface |
| **Shell fit** | Weaker — compose M3 scaffold + Shad tokens | **Stronger** — `Scaffold` + `NavigationBar` mirrors Forui |
| Dialog / sheet / toast | `ShadDialog`, `ShadSheet`, `ShadToast` | `Dialog`, `openSheet`, package toasts |
| Forms / select | `ShadSelect`, `ShadForm` | `Select`, `MultiSelect`, many inputs |
| Hybrid with current `MaterialApp` | `ShadApp.custom` + `ShadAppBuilder` | Full app shell often shadcn-native |
| **Why primary anyway** | MIT, active maintenance, wrappers already planned around leaf widgets; shell is custom either way | Escalate in Wave 0 only if `shadcn_ui` shell spike fails |
| APK / deps | Spike must measure | Spike must measure — likely larger |

**Wave 0 tie-breaker:** If `shadcn_ui` scores ≥4 on leaf widgets but <3 on tab shell ergonomics, try **one day** on `shadcn_flutter` shell only before falling to Plan C.

---

## Icon migration (`FIcons` → ?)

| Pattern | Count | Replacement strategy |
|---------|-------|----------------------|
| `FIcons.chevronLeft` / `chevronRight` | headers, tiles | `Icons.chevron_left` / `chevron_right` or Lucide |
| `FIcons.search`, `bell`, `settings` | tab headers | Material symbols matching current metaphor |
| `FIcons.rotateCw` | refresh actions | `Icons.refresh` |
| `FIcons.lock` | gated tiles | `Icons.lock_outline` |
| `FIcons.plus`, `userPlus`, `share` | CTAs | Material equivalents |

**Rule:** Icons change inside `VPage` / `VTile` / wrapper defaults — not per screen after Wave A.

---

## Wrapper implementation order (after Wave 0)

1. `VertiegeShadTheme` (or M3 theme) — unblocks all widgets  
2. `VPage` / `VTabShell` — highest leverage  
3. `showVDialog` / `VSheet` — permissions + settings spike path  
4. `VTile` / `VSectionList` — stop extending `FTile`  
5. `VButton` internal swap (API unchanged)  
6. `VFeedback` toast backend  
7. Leaf `FCard` call sites via `VCard`  

---

## Re-baseline command

```bash
bash scripts/check_no_forui_in_lib.sh --report
```

See [shadcn-migration-plan.md](shadcn-migration-plan.md) for enforcement modes.
