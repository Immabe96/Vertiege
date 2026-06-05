# Vertiege UI migration: unified design system (Forui out)

**Status:** Active — **Wave 0 gate not passed** (plan only, no library swap on `develop` yet)  
**Branch:** `docs/shadcn-migration-plan` (docs); implementation starts after Wave 0 spike PR merges.

**Goal:** One visible design system behind Vertiege `V*` wrappers. **Forui is removed gradually**, not in a big-bang rewrite.

**Historical plans & audits:** [consolidated-legacy-plans.md](../../archive/consolidated-legacy-plans.md) · [consolidated-legacy-audits.md](../../archive/consolidated-legacy-audits.md)

---

## Decision (2026-06-05)

After comparing options online and against the current codebase:

| Candidate | Verdict |
|-----------|---------|
| **`shadcn_ui`** ([pub.dev](https://pub.dev/packages/shadcn_ui), [docs](https://mariuti.com/flutter-shadcn-ui/)) | **Primary target** if Wave 0 passes — mature releases (v0.54+), MIT, good docs, shadcn/ui port |
| **`shadcn_flutter`** ([pub.dev](https://pub.dev/packages/shadcn_flutter)) | **Fallback** only if `shadcn_ui` gaps block shell/dialog/sheet on Android |
| **Forui 0.21 finish + wrappers** | **Baseline** in Wave 0 spike; **Plan B** if both shadcn ports lose on fit or SDK friction |
| **Material 3 + `V*` only** | **Plan C** — lowest third-party risk, highest build cost; use if shadcn ports add weight without UX win |

**Do not add a UI package to `develop` until Wave 0 spike PR is reviewed.** The wrapper facade (`VPage`, `VDialog`, …) is implemented **once**, with the backing library chosen in Wave 0.

---

## Why leave Forui

| | Forui (current `0.21.3`) | Target (wrapper-backed) |
|---|--------------------------|-------------------------|
| Today | `VHubPage` / `VTabPage`, uneven leaf screens mixing Material | One import path: `lib/ui/*` |
| Ecosystem | shadcn-inspired, ~40+ widgets ([forui.dev](https://forui.dev/docs)) | shadcn-style primitives + Vertiege tokens |
| Upgrade cliff | **Forui 0.22+ requires Flutter 3.44+** ([forui pub](https://pub.dev/packages/forui)); app on SDK `^3.11.0` | Spike must record min Flutter/SDK for chosen package |
| Fragmentation | Forui + Material + raw `ListTile` / `AlertDialog` | Forbidden: direct `package:forui` in feature screens after Wave A |

**Policy (effective after Wave 0 merge):** No new `import 'package:forui/forui.dart'` in feature screens. New UI goes through `lib/ui/*`. When a screen is touched, migrate its Forui/Material leaks in the same PR.

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

---

## Wave 0 — Spike & decision gate (required before Wave A)

**Branch:** `feature/ui-wave-0-spike` off `develop` after this doc merges.

**Spike screen:** `SettingsScreen` (or `LoginScreen` if faster) — dialog, list tiles, hub chrome, one sheet.

**Implement three thin prototypes** (separate folders or feature flags; not shipped to users):

1. **Baseline** — current Forui, wrappers only (no new deps).
2. **Candidate A** — `shadcn_ui` + `V*` stubs for dialog, tile, button, page scaffold.
3. **Candidate B** — Material 3 + same `V*` stubs (no shadcn package).

**Measure:**

| Criterion | How |
|-----------|-----|
| Theme alignment with `VColors` | Visual on emulator + dark mode |
| Touch targets & density | Settings list, 48dp min |
| GoRouter / hub back behavior | Unchanged |
| Analyzer / build | `flutter analyze`, debug APK size delta |
| Forui import count | `rg "package:forui" lib --count` (baseline for migration scope) |
| Maintainer fit | Docs quality, release cadence, open issues |

**Deliverables:**

- [ ] Spike PR with screenshots or short screen recording (Android).
- [ ] **Decision record** section appended to this file (package chosen, Flutter SDK bump needed or not).
- [ ] If **Plan B** (stay Forui 0.21): close Forui-removal waves; rename track to “wrapper consolidation”.
- [ ] If **shadcn_ui** wins: add dependency in Wave A PR only, not in Wave 0 doc-only merge.

**Explicitly out of Wave 0:** migrating Nexus, worlds, or dropping Forui from `pubspec.yaml`.

---

## Forui removal ladder (after Wave 0 selects shadcn or M3)

Each step must leave `flutter test` green and UAT gates intact.

1. **Wave A — App shell** (highest leverage)
   - Implement `VPage` / `VTabShell` with chosen backing.
   - Tab roots: Nexus, Explore, Chat, Identity, More.
   - FAB, overlays, Campfire mini-bar.
   - **UAT #2:** no nested tab grey voids; no inline `VLoadingCard` in world lists.

2. **Wave B — Auth & onboarding**
   - Splash, login, signup, auth callback, onboarding, The Gate.

3. **Wave C — World system**
   - Detail, manage, governance, channels, marketplace, treasury, polls, jobs, archive, academy, sanctuary.

4. **Wave D — Progression & identity**
   - Achievements, verifier, profile, `/progress` hub, hall of ascension.

5. **Wave E — Commerce & social**
   - Subscription, shop, DM, thread, Campfire, search, notifications.

6. **Wave F — Remove Forui**
   - `pubspec.yaml`: drop `forui` / `forui_assets` when `rg forui lib` is zero.
   - Delete or repoint `lib/forui/`.
   - Update [UI_STANDARDS.md](../../UI_STANDARDS.md) and [design-system.md](../reference/design-system.md).

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
- Two shadcn Flutter packages exist; **standardize on one** after Wave 0 — default **`shadcn_ui`**.

---

## Wave 0 decision record

_Fill in when spike PR merges._

| Field | Value |
|-------|-------|
| Date | |
| Chosen backing | `shadcn_ui` / `shadcn_flutter` / `material3` / `forui-0.21` |
| Flutter SDK bump required | |
| Spike PR | |
| Notes | |
