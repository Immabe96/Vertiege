# Vertiege UI migration: Forui → shadcn_flutter

**Status:** Active (2026-06-05)  
**Goal:** One visible design system — **shadcn_flutter** behind Vertiege wrappers. **Forui is removed gradually**, not in a big-bang rewrite.

**Historical plans & audits:** [consolidated-legacy-plans.md](../../archive/consolidated-legacy-plans.md) · [consolidated-legacy-audits.md](../../archive/consolidated-legacy-audits.md)

---

## Why shadcn over Forui

| | Forui (current) | shadcn_flutter (target) |
|---|-----------------|-------------------------|
| Positioning | shadcn-inspired Flutter port | Standalone shadcn/ui ecosystem for Flutter |
| Coverage | Strong headers/tabs; gaps on dialogs/sheets/lists | 84+ components, documented interop with Material + GoRouter |
| Vertiege fit | Already in `VHubPage` / `VTabPage` — good shell, uneven leaf screens | Same composable primitive story as web shadcn; easier to enforce one pattern |
| Constraint | Pinned `forui: ^0.21.3` (newer Forui wants Flutter 3.44+) | Evaluate SDK compatibility in Wave 0 spike |

**Policy:** No new direct `import 'package:forui/forui.dart'` in feature screens. New UI goes through `lib/ui/*` wrappers backed by shadcn. When a screen is touched for product work, migrate its Forui/Material leaks in the same PR.

---

## What stays

- **Material 3** as Flutter runtime where the framework requires it.
- **Brand tokens:** `VColors`, `VSpacing`, `VRadius`, `VFontSize`, `VAnimation`, motion helpers.
- **Routes:** No URL or deep-link changes during visual migration.
- **Supabase:** Schema and RLS out of scope unless a separate wave owns them.

---

## Wrapper facade (public UI API)

Implement and route all screens through these types (names may map 1:1 from today’s Forui hubs):

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

**Directory:** prefer `lib/ui/` for primitives; keep `lib/widgets/core/` for product-specific composites built from `lib/ui/`.

---

## Forui removal ladder

Each step must leave `flutter test` green and UAT gates intact.

1. **Wave 0 — Spike & dependency**
   - Add `shadcn_flutter`; prove theme + one dialog + one list row + one hub page on Android emulator.
   - Map `FHeader` / `FTabs` / `FDialog` usage counts (`rg "package:forui"`).
   - Decision log in PR: package version, bundle impact, any Material interop quirks.

2. **Wave A — App shell** (highest leverage)
   - `VTabShell` + tab roots: Nexus, Explore, Chat, Identity, More.
   - FAB, overlays, Campfire mini-bar.
   - **UAT #2:** no nested tab grey voids; no inline `VLoadingCard` in world lists.

3. **Wave B — Auth & onboarding**
   - Splash, login, signup, auth callback, onboarding, The Gate.
   - Fix cold-start: Supabase “not initialized” must not present as signed-out (infra track, same PR only if blocking).

4. **Wave C — World system**
   - Detail, manage, governance, channels, marketplace, treasury, polls, jobs, archive, academy, sanctuary.

5. **Wave D — Progression & identity**
   - Achievements, verifier, profile, `/progress` hub tabs, hall of ascension.

6. **Wave E — Commerce & social**
   - Subscription, shop, DM, thread, Campfire, search, notifications.

7. **Wave F — Remove Forui**
   - `pubspec.yaml`: drop `forui` / `forui_assets` when `rg forui lib` is zero.
   - Delete `lib/forui/` adapters or repoint to `lib/ui/`.
   - Update [UI_STANDARDS.md](../../UI_STANDARDS.md) and [design-system.md](../reference/design-system.md).

---

## Bug & infra track (parallel, not blocked on UI)

Ship on `develop` independently of visual waves where possible:

- Edge Function: validate receipt payload before nullable reads.
- Tooling: `npm test` script not a deliberate failure; asset validation without PowerShell-only path on macOS/Linux.
- Analyzer: fix warnings in touched files; ratchet toward stricter CI over time.
- Release: redact verbose crash logs in release-like builds.

Already done on `develop` (see [wave-status.md](wave-status.md)): Wave 22 drops (legacy composers, offline queue, shop P2W tabs), progress hub, post-login daily reward animation fix.

---

## Test plan

**Static (every PR touching UI):**

- `dart format --output=none --set-exit-if-changed lib test`
- `flutter analyze --no-fatal-infos` (tighten per directory over time)
- `scripts/check_no_service_role_in_lib.sh`
- `scripts/check_core_achievement_assets.py` (or documented fallback)

**Automated:** existing route, auth, notification, invite, composer, and world-channel tests must stay green.

**Visual smoke (Android release APK):**

- Tab roots: no overlap, safe areas respected.
- World detail: no grey void (UAT #2).
- Sheets/dialogs: consistent padding and 48dp touch targets.
- Auth/onboarding readable on small phones.
- Campfire: locked / connecting / error / connected visually distinct.

**Regression gates:** UAT #1 achievement PNGs; UAT #2 world-detail layout.

---

## Research links

- [shadcn/ui](https://ui.shadcn.com/) — open-code components
- [Radix Primitives](https://www.radix-ui.com/primitives) — accessibility primitive model
- [shadcn_flutter on pub.dev](https://pub.dev/packages/shadcn_flutter)
- [Forui on pub.dev](https://pub.dev/packages/forui) — current dependency, to be removed

---

## Assumptions

- Migration is **visual and consistency**, not product behavior.
- **Incremental adoption** only through wrappers.
- **Android release** remains primary UAT surface until iOS parity is explicit.
