# Vertiege — Perfection backlog (2026-05-30)

Living tracker for the six-wave “near perfection” pass. Source audits: [2026-05-21-full-app-audit.md](./2026-05-21-full-app-audit.md), [2026-05-24-ui-ux-fix-tracker.md](../audits/2026-05-24-ui-ux-fix-tracker.md), [2026-05-24-fix-tracker.md](../audits/2026-05-24-fix-tracker.md).

---

## Wave 0 — Baseline (ship what we have)

| Item | Status | Notes |
|------|--------|-------|
| `flutter test` green | Done | 184 tests (2026-05-30) |
| Core achievement assets 110/110 | Done | `scripts/check_core_achievement_assets.py` |
| UI/UX polish batch (Discover, Nexus, Feed, Identity, Search, Chat, worlds) | Done | See git diff on `develop` |
| Comment FAB vs bottom sheets | Done | `tab_shell_overlay_provider` + `tab_aware_sheet.dart` |
| `PERFECTION-BACKLOG.md` | Done | This file |
| Commit + optional release APK | Done | `main` @ `080e1a5`+; Wave 7 batch uncommitted |

---

## Wave 1 — Correctness & navigation

| ID | Item | Status | Notes |
|----|------|--------|-------|
| P0-1 | Nexus Challenges → `/challenges` | Done | `nexus_shortcuts_section.dart` |
| P0-2 | `world_hub_tab` dead/wrong route | Done | File removed |
| P0-3 | Revoke anon EXECUTE on privileged RPCs | Done | Wave 4 `20260528130000_*` |
| P0-4 | Achievement AI copy vs behavior | Partial | No “AI-Verified” strings; verify proof sheet copy |
| P1-2 | Identity Following/Allies routes | Done | `/following`, `/allies` |
| P1-6 | Router invite accept `mounted` | Done | `_AcceptInviteScreen._accept` |
| P1-7 | Settings async `context.mounted` | Done | Prior pass |
| — | League bento `onTap` | Done | `leaguesPath()` |
| — | Tab-aware sheets (reactions, report, notifications) | Done | `showTabAwareModalBottomSheet` |
| P2-2 | Dead `achievement_grid.dart` | Done | Removed |
| P1-1 | Identity duplicate achievement links | Done | Single `/achievements` via Honours header + trophy wall |
| P1-5 | Nexus / Identity / More overlap | Done | [navigation-map.md](../../guides/navigation-map.md); Nexus “Progress shortcuts” |

---

## Wave 2 — Data & state honesty

| Item | Status | Notes |
|------|--------|-------|
| `userFacingLoadError` helper | Done | `lib/utils/provider_errors.dart` |
| `SyncWarningBanner` widget | Done | Cache/sync warnings with retry |
| Post feed: all worlds fail / partial | Done | `post_provider` + Nexus warning vs error |
| Chat DM/channel message load errors | Done | `messagesLoadErrors` + room/channel UI |
| Notifications friendly errors | Done | `notification_provider` |
| Channel list friendly errors | Done | `channel_provider` |
| Identity / achievements sync banners | Done | Profile + achievement warnings |
| Background RPC swallow (rep, referral) | Deferred | Non-user-visible; log only if needed |

---

## Wave 3 — UI/UX consistency

| Item | Status | Notes |
|------|--------|-------|
| U01–U12 tracker items | Done | 2026-05-24 doc |
| Hub screens on `VHubPage` | Done | League, challenges, quests, season, profile |
| `VHubPage.titleWidget` | Done | Inline search header |
| Search → Forui shell | Done | `search_screen.dart` |
| Challenges load errors | Done | `challenge_provider` + retry |
| League friendly errors | Done | `userFacingLoadError` |
| Daily quests empty/refresh | Done | `AppEmptyState` + header refresh |
| Remaining raw `Scaffold` (auth, world detail, threads) | Open | P2-1 remainder |

---

## Wave 4 — Security (Supabase)

| Item | Status | Notes |
|------|--------|-------|
| P0-3 anon RPC revoke | Done | Verified empty on prod; sweeps in `20260528130000_*` |
| Maintenance RPC → service_role only | Done | `20260530140000_wave4_security_hardening.sql` applied |
| `award_rep_milestone_xp` auth.uid guard | Done | Same migration |
| RLS `activity_xp_log` / `tier_perks` reads | Done | Self-read + public tier perks |
| P1-8 storage listing policies | Done | `20260524120000_storage_listing_hardening.sql` |
| P1-9 leaked password protection | Open | Supabase Pro dashboard only |
| Security check script | Done | `scripts/check_supabase_security.sql` |

---

## Wave 5 — Code health

| Item | Status | Notes |
|------|--------|-------|
| P2-3 analyzer unused symbols | Done | Prior refactors; no current hits |
| Create post Forui shell | Done | `FScaffold` + `FHeader.nested` |
| `v_context_colors` consolidation | Open | Large refactor |
| Test coverage for navigation edge cases | Open |
| Thread / channel / campfire Forui | Done | `FScaffold` + thread load errors |
| World detail `FScaffold` + tools sheet | Done | No end drawer; Forui `showAppSheet` |
| Raw `Scaffold` (auth, splash) | Open | Expected for auth flows |

---

## Wave 6 — UAT & release

| Item | Status | Notes |
|------|--------|-------|
| [WAVE-4-DEVICE-CHECKLIST.md](../uat/WAVE-4-DEVICE-CHECKLIST.md) | Open | Full world IA pass |
| [PERFECTION-SMOKE-CHECKLIST.md](../uat/PERFECTION-SMOKE-CHECKLIST.md) | Added | Waves 0–5 regression smoke |
| Release APK smoke on emulator | Open | Run after each wave batch |

---

## Next actions

**Product roadmap:** [`PLAN.md`](../../PLAN.md) (audit completion plan, Waves 7–12). Baseline Waves 0–6 live here.

1. Wave 6: Device UAT sign-off (`docs/uat/WAVE-4-DEVICE-CHECKLIST.md`); UAT #1–#2 are regression-only per `PLAN.md` Wave 12.
2. Wave 7+: Execute `PLAN.md` (voice/Lounge, composer, commerce, governance, seasons, release polish).
3. Dashboard: enable leaked-password protection when on Supabase Pro.
