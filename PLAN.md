# Vertiege — Social stack plan (canonical)

**Status:** Active · **Created:** 2026-06-06 · **Waves S1–S11:** delivered on `develop` · **S9:** in progress (improvements backlog)
**Supersedes:** All docs in `docs/archive/planning/` (DCX redesign, perfection backlog, wave status, waves 13–22, shadcn migration plan, etc.)

Vertiege's next engineering focus: make **posts, notifications, presence, and chat** reliable and competitive with modern social/chat apps — without conflating **identity verification** (government ID tick) with **achievement proof** (Nexus standing).

---

## Product shell (unchanged)

| Tab | Job |
|-----|-----|
| **Nexus** | Public standing feed — verified moments, progression |
| **Chat** | Worlds, channels, DMs, Campfire |
| **Identity** | Passport / national ID tick, honour wall, tier |

Borrow **layout patterns** from popular chat apps; use Vertiege lexicon in all UI copy (world, resident, achievement, Campfire — not competitor product names).

---

## Waves S1–S6 (all delivered)

| Wave | Focus | Status |
|------|-------|--------|
| S1 | Stop the bleeding (P0) | ✅ |
| S2 | Feel alive (P1) | ✅ |
| S3 | Social polish (P2) | ✅ |
| S4 | Unread & threads (P2) | ✅ |
| S5 | Mentions & activity (P2) | ✅ |
| S6 | Chat polish + send-state | ✅ |
| S7 | Audit bugfixes + UX polish | ✅ |
| S8 | Mass swarm audit fixes (191 findings) | ✅ |
| S9 | Improvements (50 web suggestions) | 📋 in progress |
| S10 | Prestige Noir design system (Open Design) | ✅ |
| S11 | Prestige Noir completion — design system hardening | ✅ |

---

## Wave S7 — Audit bugfixes + UX polish

**Target:** ~1 week · **Exit:** All P0 functional bugs fixed; signup compliance met; code quality improvements.

### P0 — Functional Bugs

| ID | Task | File | Notes | Status |
|----|------|------|-------|--------|
| S7.1 | Fix heart animation singleton overlay + wrong color | `heart_animation.dart` | Static `_entry` replaces previous animation; color should be red/pink not violet | ✅ |
| S7.2 | Fix world delete navigates before operation completes | `world_settings_screen.dart:376` | `leaveWorld()` is unawaited; add error handling + await | ✅ |
| S7.3 | Remove back button from achievements tab root | `achievements_index.dart:56` | `showBack: true` on tab root creates confusing nav stack | ✅ |
| S7.4 | Parallelize search screen member loading | `search_screen.dart:188` | O(N*M) sequential calls → `Future.wait()` or single RPC | ✅ |
| S7.5 | Add social auth buttons to signup screen | `signup_screen.dart` | Login has Google+Apple; signup has none — inconsistency | ✅ |
| S7.6 | Add ToS/privacy policy links to signup screen | `signup_screen.dart` | **Compliance blocker** for App Store / Play Store | ✅ |
| S7.7 | Add cover/banner image to resident profile | `resident_profile_screen.dart` | No `coverImage` field in Resident model; social apps universally have this | ✅ |

### P1 — Code Quality

| ID | Task | Scope | Notes | Status |
|----|------|-------|-------|--------|
| S7.8 | Fix bare `catch (e)` blocks — add StackTrace | 6 provider files | 18 blocks fixed | ✅ |
| S7.9 | Extract oversized screens into smaller widgets | 6 screens >1000 lines | Deferred to next wave |
| S7.10 | Extract god-class providers | 3 providers >1000 lines | Deferred to next wave |
| S7.11 | Reduce app_router.dart size | 1005 lines, 82 imports | Deferred to next wave |
| S7.12 | Add i18n infrastructure | All screens | Deferred to next wave |
| S7.13 | Clean up redundant theme layer | 13 theme files | `design_system.dart` removed; `colors.dart` migration ongoing | ✅ (partial) |
| S7.14 | Replace VColors + isDark ternaries with colorScheme | ~160 files | Deferred to next wave |

### P2 — Forui Migration

| ID | Task | Scope | Notes | Status |
|----|------|-------|-------|--------|
| S7.15 | Migrate tab roots to FScaffold + FHeader | 6 tab roots | nexus, explore, chat, you, world_channel, create_post | ✅ (already migrated) |
| S7.16 | Replace SnackBar with VFeedback/Forui toaster | 1 file | world_polls_screen.dart fixed | ✅ |
| S7.17 | Replace raw TextField with FTextField | Auth screens | Zero FTextField usage in production | Deferred |
| S7.18 | Replace raw showDialog with FDialog | Dialog screens | Zero FDialog usage; all Material dialogs | Deferred |

### P3–P6 — Security, Testing, Build, Product

| ID | Task | Priority | Notes | Status |
|----|------|----------|-------|--------|
| S7.19 | Verify profile privilege guard migration applied | Security | `20260524150000` on remote; trigger `profiles_guard_privileged_columns` active on `profiles` | ✅ |
| S7.20 | Enable leaked-password protection in Supabase Auth | Security | Requires **Pro** (`password_hibp` entitlement). API returns 402 on Free. Min length raised to 8 via Management API 2026-06-29 | ⏳ Pro upgrade |
| S7.21 | Add screen widget tests | Testing | 6 widget tests; HeartAnimationOverlay, AppEmptyState, etc. | ✅ |
| S7.22 | Remove committed build artifacts | Build | `build_output.txt` removed + gitignored | ✅ |
| S7.23 | Remove duplicated `assets/staging/` | Build | Kept — used by image_gen.py pipeline | Cancelled |

---

## Wave S8 — Mass swarm audit fixes

**Target:** 2–3 weeks · **Exit:** 191 findings resolved; 50 web improvement suggestions triaged.  
**Scope:** 7 parallel agents audited all 105K lines of Dart. 191 bugs/issues + 50 web improvement suggestions.  
**Status:** ✅ **Delivered 2026-06-29** — all critical, high, and medium findings verified; residual large refactors folded into S9.

> All S8 tables below are ✅ unless noted. Hygiene items from `.kunsdd/plan/audit-the-entire-app…md` Wave 1 included at end.

### S8.1 — Critical (7 findings) · ✅

| ID | Task | Status |
|----|------|--------|
| C1–C7 | AnimatedBuilder, message copyWith, world dominion, post fields, dropdown value, invite fromSupabase, poll dedup | ✅ |

### S8.2 — High: Services (8 findings) · ✅

| ID | Task | Status |
|----|------|--------|
| H1–H8 | Invite concurrency, ally filter, reaction RPC, DM reads, push subs, council ISO dates, voice disconnect, store field | ✅ |

### S8.3 — High: State (5 findings) · ✅

| ID | Task | Status |
|----|------|--------|
| H9–H13 | Message-only persist, sign-out typing cleanup, nexus realtime reset, async notifications, XP server refresh | ✅ |

### S8.4 — High: Widgets + Screens (9 findings) · ✅

| ID | Task | Status |
|----|------|--------|
| H14–H22 | Chat list initState, VTabShell, post overflow, comment depth, share temp delete, animation pause, thread layout, typed feed | ✅ |

### S8.5 — High: Router/Repos/Models (8 findings) · ✅

| ID | Task | Status |
|----|------|--------|
| H23–H30 | Post serialization, create_post RPC, joinWorlds retry, invite deep link, thread worldId, notification fetch, reactions cast, invite expiry | ✅ |

### S8.6 — High: Config/Utils/Theme (4 findings) · ✅

| ID | Task | Status |
|----|------|--------|
| H31–H34 | Tier helpers, Prestige Noir borders, rep progress guard, standing colors | ✅ |

### S8.7–S8.11 — Medium (51 findings) · ✅

| Range | Scope | Status |
|-------|-------|--------|
| M1–M13 | Services (invites, chat batching, bootstrap mutex, typing eviction, …) | ✅ |
| M14–M21 | State (DM unsubscribe, channel reads, pagination split, voice mounted, …) | ✅ |
| M22–M26 | Screens (chat dispose, settings controllers, privacy push, season config, splash) | ✅ |
| M27–M39 | Widgets + models (semantics, season NaN, notification unknown, truncate, …) | ✅ |
| M40–M51 | Theme/utils (rate limiter, capitalize, design_system removal, onboarding auto const, …) | ✅ |

### S8 hygiene (kunsdd audit Wave 1)

| ID | Task | Status |
|----|------|--------|
| W1.1 | Gitignore `build_output.txt` + `*.log` | ✅ |
| W1.2 | Dispose dialog `TextEditingController`s in `world_jobs_screen.dart` | ✅ |

---

## Wave S10 — Prestige Noir design system (Open Design)

**Target:** ~1 week · **Exit:** Dark-only Prestige Noir globally; tab roots + hub screens match Open Design prototype.  
**Status:** ✅ **Delivered 2026-06-29** · Prototype: Open Design project `38bcaaf4-e4f2-48c2-a788-5098af479062` (Prestige Noir / Dark Luxe).

### S10.1 — Foundation

| ID | Task | Status |
|----|------|--------|
| S10.1 | `lib/theme/prestige_noir.dart` canonical palette (cool-tinted bg, gold accent, 14px bento radius) | ✅ |
| S10.2 | Dark-only `theme_provider` + `app.dart` (`ThemeMode.dark`); remove light/system scheme picker | ✅ |
| S10.3 | `VColors`, `VCommuneColors`, `VTheme`, `forui_theme` aligned to Prestige Noir | ✅ |
| S10.4 | Shared primitives: `VPrestigeCard`, `VSurfaceCard`, `prestige_noir_ui.dart` progression widgets | ✅ |

### S10.2 — Tab shell (4 tabs)

| ID | Task | Status |
|----|------|--------|
| S10.5 | Nexus — default-expanded bento, streak card, gold FAB | ✅ |
| S10.6 | Chat — gold unread badges, brand-soft rail selection | ✅ |
| S10.7 | Achievements — 2-col category grid, Verified/Pending/Available hero | ✅ |
| S10.8 | Identity — streak row, trophy wall, XP expanded by default | ✅ |

### S10.3 — Hub screens (agent swarm)

| ID | Task | Screens | Status |
|----|------|---------|--------|
| S10.9 | Auth shell | login, signup, onboarding, the_gate | ✅ |
| S10.10 | Progress | daily_quests, league, progress_hub, challenges | ✅ |
| S10.11 | Discovery + settings | search, world_discovery, settings | ✅ |
| S10.12 | Social | campfire, submit_achievement, chat_room | ✅ |
| S10.13 | World/commerce | world_detail, resident_profile, subscription, season, explore, cosmetics_shop | ✅ |

### S10.4 — Deferred (intentional vs prototype)

| Item | Notes |
|------|-------|
| World-admin screens | `world_manage`, `world_governance`, `world_treasury`, … — next polish pass |
| Consolidate `prestige_noir_ui.dart` vs `v_prestige_card.dart` | Both in use; merge in S9 |
| Discord OAuth / guest mode | Out of scope |
| Single combined login+signup route | Kept separate routes |

---

## Wave S11 — Prestige Noir completion (design system hardening)

**Target:** ~1 week · **Exit:** One color/card source of truth; screens on V* facades; legacy layers removed.  
**Status:** ✅ **Delivered 2026-07-03**

### S11.1 — Tokens & theme

| ID | Task | Status |
|----|------|--------|
| S11.1 | Delete `lib/theme/colors.dart` (`AppColors`) | ✅ |
| S11.2 | Unify card radius (`VRadius.lg` = `VRadius.bento` = 14) | ✅ |
| S11.3 | Align `VertiegeForuiTheme` type scale with `VFontSize` | ✅ |
| S11.4 | `VButton` 48dp minimum touch target | ✅ |
| S11.5 | `VTheme` dark-only; remove dead light branches | ✅ |

### S11.2 — Card & loading consolidation

| ID | Task | Status |
|----|------|--------|
| S11.6 | `VCard` — sole flat surface (replaces `VSurfaceCard`, `VSurfacePanel`, `GlassPanel`) | ✅ |
| S11.7 | `VPrestigeCard` — sole raised card (replaces `PrestigeRaisedCard`, `SovereignCard`) | ✅ |
| S11.8 | `VSpinner` facade; screen-level `CircularProgressIndicator` removed | ✅ |
| S11.9 | `VStates` (`VEmptyState`, `VLoadingState`, `VErrorState`) on Prestige Noir tokens | ✅ |

### S11.3 — Screen & widget migration

| ID | Task | Status |
|----|------|--------|
| S11.10 | Material buttons → `VButton` in all `lib/screens/` | ✅ |
| S11.11 | Remove dead `isDark ?` ternaries (screens + `lib/ui/` facades) | ✅ |
| S11.12 | `docs/reference/design-system.md` + `.cursor/rules/flutter-ui.mdc` updated | ✅ |

---

## Wave S9 — Improvements (from audit + web suggestions)

**Target:** 3–4 weeks · **Exit:** Key improvements shipped; tech debt reduced.  
**Started:** 2026-06-29 · **Partial:** Riverpod codegen (A1), secure storage (S6), App Check wiring (S9) already landed on `develop`.

### S9.1 — Architecture (10 items)

| ID | Task | Priority | Status |
|----|------|----------|--------|
| A1 | Migrate to Riverpod code generation (`@riverpod`) | HIGH | ✅ (core providers) |
| A2 | Use `AsyncNotifier` for all server-state providers | HIGH | 📋 |
| A3 | Implement provider families for parameterized data | HIGH | 📋 partial |
| A4 | Separate repository layer from services (~70 services, 4 repos) | MEDIUM | 📋 |
| A5 | Use `autoDispose` on all providers | HIGH | 📋 |
| A6 | Add Riverpod lint rules to `analysis_options.yaml` | MEDIUM | 📋 |
| A7 | Extract router redirect logic into testable pure functions | LOW | 📋 |
| A8 | Feature-based folder structure (`lib/features/`) | MEDIUM | 📋 |
| A9 | Unit tests for all service business logic (target 80%+) | HIGH | 📋 |
| A10 | Use Freezed for immutable models | MEDIUM | 📋 partial |

### S9.2 — Performance (10 items)

| ID | Task | Priority |
|----|------|----------|
| P1 | Verify `ListView.builder` on all feeds | HIGH |
| P2 | Verify Impeller enabled on Android + iOS | HIGH |
| P3 | Audit `const` constructors across V* facades | HIGH |
| P4 | Implement `cached_network_image` with server-side resize | HIGH |
| P5 | Wrap heavy animations in `RepaintBoundary` | MEDIUM |
| P6 | Lazy-load services after first frame (extend stagger) | HIGH |
| P7 | Offload heavy computation to isolates | MEDIUM |
| P8 | Async font loading + subsetting | MEDIUM |
| P9 | Offline caching for read-heavy data (Hive/Isar) | MEDIUM |
| P10 | Profile on physical devices; document DevTools workflow | LOW |

### S9.3 — Security (10 items)

| ID | Task | Priority |
|----|------|----------|
| S1 | Enable RLS on every table at creation time | HIGH |
| S2 | Use `auth.uid()` in all RLS policies | HIGH |
| S3 | Validate JWT in all Edge Functions | HIGH |
| S4 | Input validation on client AND server | HIGH |
| S5 | Secure OAuth redirect URIs | MEDIUM |
| S6 | Use `flutter_secure_storage` for tokens | HIGH | ✅ |
| S7 | Implement rate limiting awareness | MEDIUM | 📋 |
| S8 | Audit RLS policies quarterly | MEDIUM | 📋 |
| S9 | Enforce Firebase App Check | HIGH | ✅ partial (`supabase_app_check.dart`) |
| S10 | Document security architecture in `docs/guides/` | LOW |

### S9.4 — UX/Design (10 items)

| ID | Task | Priority |
|----|------|----------|
| U1 | Infinite scroll + skeleton loading on all feeds | HIGH | 📋 partial |
| U2 | Pull-to-refresh on every list screen | HIGH | 📋 partial |
| U3 | Haptic feedback on key interactions | MEDIUM |
| U4 | WCAG 2.2 accessibility audit | HIGH |
| U5 | Smart onboarding with progressive disclosure | MEDIUM |
| U6 | Optimistic UI updates (like/bookmark/send) | HIGH |
| U7 | Swipe gestures on feed items | MEDIUM |
| U8 | Network status indicators | MEDIUM |
| U9 | Skeleton screens for profile loading | MEDIUM |
| U10 | Meaningful empty states with CTAs | MEDIUM |

### S9.5 — Firebase/Supabase + Flutter 3.x (10 items)

| ID | Task | Priority |
|----|------|----------|
| F1 | Firebase Remote Config for feature flags | HIGH |
| F2 | Real-time Remote Config for kill switches | MEDIUM |
| F3 | Export Crashlytics to BigQuery | MEDIUM |
| F4 | Supabase Realtime Presence for chat presence | HIGH |
| F5 | Edge Functions retry logic for push delivery | HIGH |
| F6 | Material Design 3 dynamic color | MEDIUM | ⏭️ skipped (Prestige Noir dark-only) |
| F7 | `SemanticsRole` for screen readers | MEDIUM |
| F8 | WASM compilation for web target | LOW |
| F9 | Dart records + pattern matching where applicable | MEDIUM |
| F10 | Defer FlutterGenUI (2026 roadmap) | LOW |

---

## Post-S7 backlog (carried forward)

| Item | Notes |
|------|-------|
| Real Report flow | `reports` table + admin view (S6.L was a toast stub) |
| Honest streak UI + server reconcile | `record_daily_check_in` exists; tighten Identity display |
| World activity map (full) | S5 shipped preview avatars in Messages panel |
| @AllResidents / nearby aliases | Broadcast mentions work; expand tests |
| Voice messages | New feature |
| Search-in-conversation | New feature |
| Quick-reply from push notification | New feature |
| "Last seen X ago" tooltip on profile | Different surface |

---

## Test plan

| Suite | Covers |
|-------|--------|
| `post_provider_test` | Cache hydrate, partial failure, pagination |
| `notification_provider_test` | Recipient ID, no duplicate delivery |
| `chat_unread_test` | DM + channel unread math |
| `chat_provider_reaction_test` | DM add/remove reaction |
| `presence_service_test` | `last_seen` write + idle threshold |

---

## Archived planning docs

Historical plans (DCX 144/144, perfection waves 0–6, waves 13–22, shadcn migration, etc.) live in:

**`docs/archive/planning/`**

Do not update archived files for active work — update **this file** (`PLAN.md`) instead.
