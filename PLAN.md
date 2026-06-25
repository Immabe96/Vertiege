# Vertiege — Social stack plan (canonical)

**Status:** Active · **Created:** 2026-06-06 · **Waves S1–S6:** delivered on `develop`  
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
| S7.13 | Clean up redundant theme layer | 13 theme files | `design_system.dart` dead code; `app_theme.dart` single consumer |
| S7.14 | Replace VColors + isDark ternaries with colorScheme | ~160 files | Deferred to next wave |

### P2 — Forui Migration

| ID | Task | Scope | Notes | Status |
|----|------|-------|-------|--------|
| S7.15 | Migrate tab roots to FScaffold + FHeader | 6 tab roots | nexus, explore, chat, you, world_channel, create_post | ✅ (already migrated) |
| S7.16 | Replace SnackBar with VFeedback/Forui toaster | 1 file | world_polls_screen.dart fixed | ✅ |
| S7.17 | Replace raw TextField with FTextField | Auth screens | Zero FTextField usage in production | Deferred |
| S7.18 | Replace raw showDialog with FDialog | Dialog screens | Zero FDialog usage; all Material dialogs | Deferred |

### P3–P6 — Security, Testing, Build, Product

| ID | Task | Priority | Notes |
|----|------|----------|-------|
| S7.19 | Verify profile privilege guard migration applied | Security | `20260524150000_profiles_privilege_guard.sql` |
| S7.20 | Enable leaked-password protection in Supabase Auth | Security | Manual dashboard toggle |
| S7.21 | Add screen widget tests | Testing | 57 screens, 0 tests |
| S7.22 | Remove committed build artifacts | Build | `.DS_Store`, log files, `build_output.txt` |
| S7.23 | Remove duplicated `assets/staging/` | Build | ~18MB duplicated with `assets/generated/` |

---

## Post-S7 backlog

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
