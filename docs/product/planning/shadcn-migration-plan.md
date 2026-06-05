# Vertiege UI migration: unified design system

**Status:** **Wave 0 passed — Plan B (`forui-0.21`)**  
**Decision (2026-06-05):** On-device spike — **Forui baseline looks best.** No `shadcn_ui` swap; no Forui removal.  
**Revised goal:** **Wrapper consolidation** — one import path (`lib/ui/*`), Forui stays at `0.21.3` behind `V*` facades.  
**Branch / PR:** `feature/ui-wave-0-spike` → `develop` ([PR #32](https://github.com/Immabe96/Vertiege/pull/32))  
**Spike route (debug):** `/debug/ui-spike` — keep for regression; baseline is the chosen direction.  
**Snapshot:** 66 `lib/` files import Forui; 35 of 54 screen files import Forui directly.

**Historical plans & audits:** [consolidated-legacy-plans.md](../../archive/consolidated-legacy-plans.md) · [consolidated-legacy-audits.md](../../archive/consolidated-legacy-audits.md)  
**Widget mapping:** [ui-widget-mapping.md](ui-widget-mapping.md) — Forui symbol inventory, per-package mapping, theme bridge.

---

## Decision (2026-06-05) — **locked: Forui 0.21**

Wave 0 spike on Android emulator; product owner picked **Forui baseline** over `shadcn_ui` and Material 3.

| Candidate | Verdict |
|-----------|---------|
| **Forui 0.21 + `V*` wrappers** | **Chosen** — best visual fit on device |
| **`shadcn_ui`** | Rejected after spike — shell/leaf feel weaker than baseline |
| **Material 3 + `V*` only** | Rejected — less polished than Forui for Vertiege chrome |
| **`shadcn_flutter`** | Not trialed — not needed after baseline win |

**Do not add `shadcn_ui` to production paths.** Wrapper facade (`VPage`, `VDialog`, …) is implemented **once**, backed by **Forui** inside `lib/ui/` and `lib/forui/`.

---

## Why stay on Forui (post–Wave 0)

| | Today | Wrapper consolidation target |
|---|-------|------------------------------|
| Shell | `VHubPage` / `VTabPage` | Rename/move to `lib/ui/shell/` — **still Forui inside** |
| Leaf screens | Forui + Material + raw `ListTile` mixed | One import path: `lib/ui/*` for feature code |
| Upgrade | Pinned `0.21.3` until a deliberate Flutter/Forui bump wave | **Do not** jump to Forui 0.22+ without a dedicated compat spike |
| Layout pitfalls | e.g. `FTile.raw` + `Expanded` (Settings Appearance — fixed) | Document patterns in [design-system.md](../../reference/design-system.md) |

**Policy (effective now):** No new `import 'package:forui/forui.dart'` in feature screens. New UI goes through `lib/ui/*`. When a screen is touched, route Forui/Material leaks through wrappers in the same PR. **Forui is not removed from `pubspec.yaml`.**

---

## What stays

- **Material 3** as Flutter runtime where the framework requires it.
- **Brand tokens:** `VColors`, `VSpacing`, `VRadius`, `VFontSize`, `VAnimation`, motion helpers.
- **Routes:** No URL or deep-link changes during visual migration.
- **Supabase:** Schema and RLS out of scope unless a separate wave owns them.

---

## Wrapper facade (public UI API)

Screens depend on these types only. **Backing library is an implementation detail** inside `lib/ui/`.

| Wrapper | Replaces today | Notes |
|---------|----------------|-------|
| `VPage` | `VHubPage`, hub scaffolds | title, back, actions, body |
| `VTabShell` | `VTabPage` | bottom/tab shell only |
| `VSheet` | `showModalBottomSheet`, glass sheets | bottom + side patterns |
| `VDialog` | `AlertDialog`, `FDialog`, `VDialog` | confirm / error / action |
| `VTile` | `ListTile`, `VSectionTile` | settings & list rows |
| `VButton` | `FButton`, `FilledButton` mix | primary / outline / ghost |
| `VInput` | raw `TextField`, composer fields | labels, errors, a11y |
| `VStateView` | `AppEmptyState`, `ScreenLoading`, inline loaders | loading / empty / error / offline |
| `VBadge`, `VCard` | chips, `FCard`, custom surfaces | feed & shop cards |

**Directory:** `lib/ui/` for primitives; `lib/widgets/core/` for product composites built from `lib/ui/`.

### Today vs target (rename only — API stable)

| Today | Wave A target | Notes |
|-------|---------------|-------|
| `lib/forui/v_hub_page.dart` → `VHubPage` | `lib/ui/shell/v_page.dart` → `VPage` | Same constructor surface; re-export from `ui.dart` |
| `lib/forui/v_tab_page.dart` → `VTabPage` | `lib/ui/shell/v_tab_shell.dart` → `VTabShell` | Tab roots + `FBottomNavigationBar` replacement |
| `lib/widgets/v_section_list.dart` | `lib/ui/lists/v_tile.dart` → `VTile`, `VSectionList` | Stop subclassing `FTile` in feature code |
| `lib/widgets/core/v_dialog.dart` → `showVDialog` | `lib/ui/overlays/v_dialog.dart` | Keep `showVDialog` name for call sites |
| `lib/widgets/core/glass_sheet.dart` | `lib/ui/overlays/v_sheet.dart` → `VSheet` | Campfire / Nexus sheets |
| `lib/ui/buttons/v_button.dart` | stays; swap `FButton` internally | Already the right facade |
| `lib/theme/forui_theme.dart` | `lib/theme/v_shell_theme.dart` | Map `VColors` → chosen package theme |

**Deprecation path:** `lib/forui/` deleted in Wave F after all imports move to `lib/ui/`.

---

## Current inventory (baseline for Wave 0)

Re-run before spike PR:

```bash
bash scripts/check_no_forui_in_lib.sh --report   # file list + counts (baseline: 65)
# Optional ripgrep breakdown:
rg "package:forui" lib/screens --count | wc -l    # screen files (baseline: 35)
```

### Forui import hotspots (migrate early in shell wave)

| Area | Files | Risk |
|------|-------|------|
| Tab shell | `tab_layout.dart`, `v_tab_page.dart`, `app.dart`, `app_router.dart` | Breaks all navigation if wrong |
| Settings pattern | `settings_screen.dart`, `v_section_list.dart` | Spike screen — reference implementation |
| World dossier | `world_realm_dossier.dart`, `world_detail_screen.dart` | Dense `FCard` / `FTile` usage |
| Chat / thread | `chat_room_screen.dart`, `thread_screen.dart` | Multiple sheets + composer chrome |
| Dialogs | `v_dialog.dart`, `tier_up_dialog.dart`, `prestige_up_dialog.dart`, `device_permission_service.dart` | Must preserve modal a11y |

### Screens without direct Forui import (19)

Material-first or wrapper-only — still in scope when parent shell changes, but lower priority per wave:

`splash_screen`, `login_screen`, `signup_screen`, `verifier_login_screen`, `onboarding_screen`, `the_gate_screen`, `more_screen`, `alerts_screen`, `nexus_notifications_sheet`, `resident_profile_screen`, `connections_screen`, `season_screen`, `world_manage_screen`, `world_marketplace_screen`, `world_treasury_screen`, `world_sanctuary_screen`, `world_archive_screen`, `audit_log_screen`, `ascension_path_screen`

### Legacy Material leaks (grep targets during each wave)

`ListTile`, raw `AlertDialog`, raw `Scaffold(` still appear in ~25 screen files. Each wave PR should reduce counts in touched files; do not drive-by unrelated screens.

---

## Wave 0 — Spike & decision gate (required before Wave A)

**Branch:** `feature/ui-wave-0-spike` off `develop` **after** this doc PR merges to `develop`. Until then, continue polishing on `docs/shadcn-migration-plan` only.

**Spike screen:** `SettingsScreen` (primary) — already has section lists, dialogs, theme picker, and hub entry. **Fallback:** `LoginScreen` if auth theme wiring blocks settings isolation.

**Spike must exercise these primitives:**

| Primitive | Settings coverage |
|-----------|-------------------|
| `VPage` / hub chrome | Screen scaffold + app bar actions |
| `VTile` / section list | Account, notifications, appearance sections |
| `VDialog` | Sign-out confirm, permission explainer |
| `VButton` | Primary CTA rows |
| `VSheet` | Theme scheme picker or notification sheet pattern |
| Dark + light | Toggle in Settings → re-open spike route |

**Implement three thin prototypes** under `lib/ui_spike/` (never imported from production routes):

```
lib/ui_spike/
  baseline/          # Forui 0.21 — wrappers as today
  shadcn_ui/         # Candidate A
  material3/         # Candidate B (no shadcn package)
  spike_settings_page.dart   # shared layout contract, three backends
```

Wire via **debug-only** route `/debug/ui-spike` (guarded by `kDebugMode` or existing dev menu if present). Do not ship spike route in release builds.

1. **Baseline** — current Forui, wrappers only (no new deps).
2. **Candidate A** — `shadcn_ui` + `V*` stubs for dialog, tile, button, page scaffold.
3. **Candidate B** — Material 3 + same `V*` stubs (no shadcn package).

Optional **Candidate C** (`shadcn_flutter`) only if A fails on dialog/sheet but B feels too heavy — time-box to ½ day.

**Measure (fill scores 1–5 in spike PR):**

| Criterion | How | Baseline | A | B |
|-----------|-----|----------|---|---|
| Theme alignment with `VColors` | Visual on emulator, light + dark | | | |
| Touch targets & density | Settings list, 48dp min | | | |
| GoRouter / back behavior | Pop from nested hub | | | |
| Analyzer / build | `flutter analyze`, debug APK | | | |
| APK size delta vs baseline | `app-release.apk` bytes | 0 | | |
| Dialog + sheet animation | No jank, correct barrier | | | |
| Typography (Plus Jakarta) | Matches `VFont` scale | | | |
| Maintainer fit | Docs, releases, issue velocity | n/a | | |
| Min Flutter / Dart SDK | `pubspec` constraint note | SDK `^3.11.0` | | |
| Tab shell ergonomics | `VTabShell` + back stack on emulator | | | |
| Settings row density | `VTile` / section list | | | |

**Known spike risks (see [ui-widget-mapping.md](ui-widget-mapping.md)):**

- `shadcn_ui` has strong leaf widgets but **no Forui-style page scaffold** — `VPage` likely composes Material `Scaffold` + `ShadTheme`.
- `shadcn_flutter` has closer `Scaffold` + `NavigationBar` — time-box Candidate C if shell scores low.
- `FIcons` in 24 files — spike may use Material icons; batch replace in Wave A.

**Theme spike checklist:**

- [ ] Map `VColors.primary`, surfaces, `mutedForeground`, `destructive` to candidate theme tokens.
- [ ] Preserve `context.vOnSurface` / `v_context_colors.dart` — wrappers read Vertiege tokens, not package defaults.
- [ ] Document whether `FTheme` / `FToaster` / `FTooltipGroup` equivalents exist or Material overlay suffices.

**Deliverables:**

- [x] Spike code: `lib/ui_spike/` — baseline / `shadcn_ui` / Material 3 backends.
- [x] Debug route `/debug/ui-spike` (tree-shaken from release).
- [x] `shadcn_ui: ^0.54.0` in `pubspec.yaml` (spike branch only until PR merges).
- [x] `VertiegeShadTheme` token bridge (`lib/ui_spike/shadcn_ui/vertiege_shad_theme.dart`).
- [ ] On-device score table (light + dark) — fill decision record below.
- [ ] Spike PR with screenshots or short screen recording (Android).
- [ ] If **Plan B** (stay Forui 0.21): close Forui-removal waves; rename track to “wrapper consolidation”.

**Wave 0 PR template (copy into PR body):**

```markdown
## UI Wave 0 spike

- Spike route: `/debug/ui-spike` (debug only)
- Screen: Settings (or Login)
- Backends: baseline / shadcn_ui / material3

### Scores (1–5)
| Criterion | Baseline | shadcn_ui | material3 |
|-----------|----------|-----------|-----------|
| Theme fit | | | |
| Density / touch | | | |
| Dialog + sheet | | | |
| Build / analyze | | | |
| Maintainer | n/a | | |

### Recommendation
- [ ] shadcn_ui → proceed to Wave A
- [ ] material3 only → Plan C
- [ ] stay Forui 0.21 → wrapper consolidation

### SDK impact
- Flutter min: 
- New deps: 

### Screenshots
(light + dark for chosen winner)
```

**Explicitly out of Wave 0:** migrating Nexus, worlds, or dropping Forui from `pubspec.yaml`.

---

## ~~Forui removal ladder~~ — **cancelled (Plan B)**

_Waves A–F below are **historical** — kept for inventory only. Do not execute Forui removal._

---

## Wrapper consolidation ladder (active track)

Same screen groupings as the old ladder, but **Forui remains the backing library** inside `lib/ui/` / `lib/forui/`. No `pubspec` swap.

### W1 — Shell & layout patterns (highest leverage) — **in progress**

- [x] `VPage` / `VTabShell` in `lib/ui/shell/`; `VHubPage` / `VTabPage` typedefs for compat.
- [x] `ui.dart` exports shell; `shadcn_ui` removed; debug spike = Forui baseline only.
- [x] Settings Appearance `Card` layout fix; design-system layout rules documented.
- [ ] Migrate feature screens to `import 'package:vertiege/ui/ui.dart'` (incremental).
- [ ] Tab roots grey-void UAT #2 pass.

### W2 — Auth & onboarding

- Splash, login, signup, callback, onboarding, The Gate — inherit shell tokens; `VButton` only.

### W3 — World system

- World detail, manage, governance, channels, marketplace, dossier widgets — batch wrapper imports.

### W4 — Progression & identity

- Progress hub, achievements, league, profile, ascension.

### W5 — Commerce & social

- Shop, subscription, chat, thread, Campfire, search.

### W6 — Hygiene (not removal)

- `rg "package:forui" lib/screens` trending down via wrappers; **keep** `forui` in `pubspec`.
- Optional: drop `shadcn_ui` dep + shadcn spike backend after PR merge (debug baseline-only).
- Update [design-system.md](../../reference/design-system.md) — “Forui behind V* wrappers”, not “migrate to shadcn”.

---

## Historical: Forui removal ladder (pre–Wave 0, do not run)

Each step must leave `flutter test` green and UAT gates intact. **One wave per PR** preferred; max two related screens if they share a wrapper change.

**Per-PR definition of done:**

- No new `package:forui` imports in touched feature files.
- Touched screens use `lib/ui/*` or existing composites only.
- `rg "package:forui" lib/path/to/touched` → zero for migrated files.
- Visual smoke on Android for changed routes.

### Wave A — App shell (highest leverage)

| File / route | Forui today | Action |
|--------------|-------------|--------|
| `app.dart`, `theme/forui_theme.dart` | `FTheme`, toaster | Swap shell theme provider |
| `router/app_router.dart` | transitions | Keep routes; swap page chrome |
| `tabs/tab_layout.dart`, `forui/v_tab_page.dart` | `FScaffold`, bottom nav | → `VTabShell` |
| `tabs/nexus_screen.dart` | mixed | Tab body only |
| `tabs/explore_screen.dart` | mixed | Tab body |
| `tabs/chat_list_screen.dart` | mixed | Tab body |
| `tabs/identity_screen.dart` | mixed | Tab body |
| `tabs/more_screen.dart` | Material | Align with new shell tokens |
| `tabs/alerts_screen.dart` | Material | Notification list chrome |
| Campfire mini-bar overlay | via `tab_shell_overlay_provider` | No layout regression |

**UAT #2:** no nested tab grey voids; no inline `VLoadingCard` in world lists.

### Wave B — Auth & onboarding

| Screen | Notes |
|--------|-------|
| `splash_screen.dart` | Brand motion only |
| `auth/login_screen.dart`, `signup_screen.dart`, `verifier_login_screen.dart` | No Forui today — theme inheritance from shell |
| `auth/auth_callback.dart` | Heavy import — migrate with dialog helper |
| `onboarding/onboarding_screen.dart`, `the_gate_screen.dart` | Gate copy + CTA buttons → `VButton` |

### Wave C — World system

| Screen | Forui import |
|--------|----------------|
| `world_detail_screen.dart` | yes |
| `world_manage_screen.dart` | no (parent shell) |
| `world_settings_screen.dart` | yes |
| `world_governance_screen.dart` | yes |
| `world_channel_screen.dart` | yes |
| `world_marketplace_screen.dart` | no |
| `world_treasury_screen.dart` | no |
| `world_polls_screen.dart` | yes |
| `world_jobs_screen.dart` | yes |
| `world_archive_screen.dart` | no |
| `world_academy_screen.dart` | yes |
| `world_sanctuary_screen.dart` | no |
| `world_discovery_screen.dart` | yes |
| `world_members_screen.dart` | yes |
| `world_challenges_screen.dart` | yes |
| `create_world_screen.dart` | yes |
| Widgets: `world_realm_dossier`, `world_home_tab`, `world_card`, `dossier_collapsible_section` | yes — batch with detail |

### Wave D — Progression & identity

| Screen | Notes |
|--------|-------|
| `progress_hub_screen.dart` | Hub pattern |
| `achievements/*` | Index, category, submit |
| `verification_review_screen.dart` | Verifier tools |
| `resident_profile_screen.dart` | Material header — align with `VPage` |
| `hall_of_ascension_screen.dart`, `journey/ascension_path_screen.dart` | Progression chrome |
| `league_screen.dart`, `challenges_screen.dart`, `daily_quests_screen.dart`, `season_screen.dart` | Calm ranking UI |
| `twin_seal_setup_screen.dart` | Security flow |

### Wave E — Commerce & social

| Screen | Notes |
|--------|-------|
| `subscription_screen.dart`, `cosmetics_shop_screen.dart`, `coin_history_screen.dart` | Commerce |
| `chat_room_screen.dart`, `thread_screen.dart` | Highest Forui density — schedule last in wave |
| `campfire_screen.dart` | Immersive + sheets |
| `search_screen.dart` | Search field + results |
| `tabs/nexus_notifications_sheet.dart` | Sheet pattern |
| `connections_screen.dart` | Social graph |

### Wave F — Remove Forui

- `pubspec.yaml`: drop `forui` / `forui_assets` when `rg "package:forui" lib` is zero.
- Delete `lib/forui/`; remove `lib/ui_spike/` if still present.
- Add CI guard: `scripts/check_no_forui_in_lib.sh` (fail if `package:forui` outside allowlist during transition — remove allowlist in Wave F).
- Update [UI_STANDARDS.md](../../UI_STANDARDS.md) and [design-system.md](../reference/design-system.md).

**Estimated scope:** ~65 files → 0 Forui imports across six implementation waves after Wave 0.

---

## Enforcement (after Wave 0 merges to `develop`)

| Phase | Rule |
|-------|------|
| Wave A+ | No new `import 'package:forui/forui.dart'` in `lib/screens/` or `lib/widgets/` |
| Wave A+ | New UI must import `package:vertiege/ui/ui.dart` (or specific `lib/ui/` paths) |
| Wave C+ | `rg "package:forui" lib/screens` count must not increase week-over-week |
| Wave F | Zero Forui imports repo-wide |

**Allowed during transition:** `lib/ui/`, `lib/theme/`, `lib/forui/` (until deleted), `lib/ui_spike/` (debug).

**Script:** `scripts/check_no_forui_in_lib.sh`

| Mode | When |
|------|------|
| `--report` | Now — baseline tracking, always passes |
| `--enforce-screens` | After Wave A merges — add to CI `ui` job |
| `--enforce-zero` | Wave F — fail if any Forui import remains |

Allowlist lives in the script header; shrink it each wave as files migrate.

---

## Risks & mitigations

| Risk | Mitigation |
|------|------------|
| Flutter SDK bump blocks release | Record min SDK in Wave 0; stay on Forui 0.21 if bump > one minor |
| `shadcn_ui` vs `shadcn_flutter` API drift | Standardize on one package in Wave 0; no dual-deps |
| Tab shell regression (grey void UAT #2) | Wave A ships with world-detail smoke test checklist |
| Chat/thread composer breakage | Wave E last; keep spike sheet pattern from Wave 0 |
| Theme flash on cold start | Spike must cover `app.dart` provider order |
| APK bloat | Record size delta in Wave 0; reject if > ~3% without UX win |

**Rollback:** Each wave is revertible independently. Do not merge Wave F until Wave A has soaked one release cycle on internal track.

---

## Bug & infra track (parallel)

Ship on `develop` independently of UI waves where possible:

- Edge Function: validate receipt payload before nullable reads.
- Tooling: `npm test` not a deliberate failure; asset validation without PowerShell-only path on macOS/Linux.
- Analyzer: fix warnings in touched files.
- Cold-start auth: Supabase “not initialized” must not present as signed-out.

Already on `develop`: Wave 22 drops, progress hub, daily reward `TweenSequence` fix ([wave-status.md](wave-status.md)).

---

## Test plan

**Every UI PR:**

- `dart format --output=none --set-exit-if-changed lib test`
- `flutter analyze --no-fatal-infos`
- `flutter test --no-pub`
- `scripts/check_no_service_role_in_lib.sh`
- `scripts/check_no_forui_in_lib.sh --report` (Wave A+: `--enforce-screens` in CI)
- Achievement asset check (or documented fallback)

**Visual smoke (Android release APK):**

- Tab roots: no overlap; safe areas OK.
- World detail: no grey void (UAT #2).
- Sheets/dialogs: consistent padding, 48dp targets.
- Auth readable on small phones.
- Campfire states visually distinct.

**Regression gates:** UAT #1 achievement PNGs; UAT #2 world-detail layout.

---

## Research links

- [shadcn/ui](https://ui.shadcn.com/) — design philosophy (open code, composable)
- [shadcn_ui](https://pub.dev/packages/shadcn_ui) — **primary Flutter port candidate**
- [shadcn_flutter](https://pub.dev/packages/shadcn_flutter) — alternate port (New York style, 84+ components)
- [Forui](https://pub.dev/packages/forui) — current dependency
- [Material 3 for Flutter](https://m3.material.io/develop/flutter) — Plan C baseline

---

## Assumptions

- Migration is **visual and consistency**, not product behavior.
- **Incremental adoption** only through wrappers.
- **Android release** remains primary UAT surface until iOS parity is explicit.
- Wave 0 **rejected** shadcn ports for production; spike artifacts may remain debug-only until cleanup.

---

## Wave 0 decision record

| Field | Value |
|-------|-------|
| Date | 2026-06-05 |
| Chosen backing | **`forui-0.21`** (Plan B — wrapper consolidation) |
| Runner-up | `shadcn_ui`, Material 3 — visually weaker on emulator |
| Flutter SDK bump required | **No** for current pin |
| APK size delta (vs baseline) | Not blocking — no shadcn production dep |
| Spike PR | [#32](https://github.com/Immabe96/Vertiege/pull/32) |
| Forui file count at spike start | 66 |
| Notes | Product owner: **“Forui baseline looks best.”** Settings scroll bugs fixed during spike (Appearance `Card` layout). Next: W1 shell rename, not Forui removal. |

---

## Doc changelog

| Date | Change |
|------|--------|
| 2026-06-05 | Initial plan + Wave 0 gate |
| 2026-05-30 | Inventory baseline, screen matrix, spike folder layout, PR template, enforcement |
| 2026-05-30 | Widget mapping doc, theme bridge, `check_no_forui_in_lib.sh` |
| 2026-05-30 | Wave 0 spike implemented (`lib/ui_spike/`, debug route, `shadcn_ui` dep) |
| 2026-06-05 | **Wave 0 decision: Forui 0.21 (Plan B)** — wrapper consolidation track |
