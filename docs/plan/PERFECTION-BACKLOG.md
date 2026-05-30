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
| Commit + optional release APK | In progress | After analyze |

---

## Wave 1 — Correctness & navigation

| ID | Item | Status | Notes |
|----|------|--------|-------|
| P0-1 | Nexus Challenges → `/challenges` | Done | `nexus_shortcuts_section.dart` |
| P0-2 | `world_hub_tab` dead/wrong route | Done | File removed |
| P0-3 | Revoke anon EXECUTE on privileged RPCs | Open | Supabase migration (Wave 4) |
| P0-4 | Achievement AI copy vs behavior | Partial | No “AI-Verified” strings; verify proof sheet copy |
| P1-2 | Identity Following/Allies routes | Done | `/following`, `/allies` |
| P1-6 | Router invite accept `mounted` | Done | `_AcceptInviteScreen._accept` |
| P1-7 | Settings async `context.mounted` | Done | Prior pass |
| — | League bento `onTap` | Done | `leaguesPath()` |
| — | Tab-aware sheets (reactions, report, notifications) | Done | `showTabAwareModalBottomSheet` |
| P2-2 | Dead `achievement_grid.dart` | Done | Removed |
| P1-1 | Identity duplicate achievement links | Open | Low — product tidy |
| P1-5 | Nexus / Identity / More overlap | Open | Product map |

---

## Wave 2 — Data & state honesty

| Item | Status |
|------|--------|
| Provider silent `catch (_) {}` → error UI | Open |
| Empty lists with failed fetch explained | Open |

---

## Wave 3 — UI/UX consistency

| Item | Status |
|------|--------|
| U01–U12 tracker items | Done (2026-05-24 doc) |
| Forui migration on hub screens (P2-1) | Open |
| Remaining `showModalBottomSheet` on full-screen routes (no tab FAB) | OK as-is |

---

## Wave 4 — Security (Supabase)

| Item | Status |
|------|--------|
| P0-3 anon RPC revoke | Open |
| P1-8 storage listing policies | Open |
| P1-9 leaked password protection | Open (Pro) |

---

## Wave 5 — Code health

| Item | Status |
|------|--------|
| P2-3 analyzer unused symbols | Open |
| `v_context_colors` consolidation | Open |
| Test coverage for navigation edge cases | Open |

---

## Wave 6 — UAT & release

| Item | Status |
|------|--------|
| [WAVE-4-DEVICE-CHECKLIST.md](../uat/WAVE-4-DEVICE-CHECKLIST.md) sign-off | Open |
| Release APK smoke on emulator | Partial |

---

## Next actions (after Wave 0 commit)

1. Wave 1 spot-check: achievement proof sheet copy (P0-4).
2. Wave 2: one provider at a time — `achievement_provider`, `post_provider`, `resident_provider`.
3. Wave 4: Supabase migration draft for anon RPC revoke.
