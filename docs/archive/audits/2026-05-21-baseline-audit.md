# Baseline audit — 2026-05-21

**Branch:** `develop`  
**Project:** `wjaphoaxalvgjnrwqjwe`  
**Scope:** Code health, Supabase drift, security (local SQL review), UI/UX static, persistence, product gaps.

---

## Executive summary

| Area | Status | Top action |
|------|--------|------------|
| **Code health** | Pass | 108 tests; analyze exit 0 (405 info lints) |
| **Supabase migrations** | **Reconciled (2026-05-21)** | 12 active local files match remote tail; May-12 history documented — see [migration-reconciliation](./2026-05-21-migration-reconciliation.md) |
| **Security** | **Advisor run** | 0 errors, 6 WARN categories — see [security-advisor](./2026-05-21-security-advisor.md) |
| **UI/UX (static)** | In progress | 25 files still use glass/legacy widgets; custom `_GlassNavBar` |
| **UI/UX (device)** | In progress | See [DEVICE_UAT.md](../DEVICE_UAT.md) — league tester issues logged 2026-05-22 |
| **Persistence** | Partial | Repositories exist for 5 domains; prefs still used for cache/UI prefs |
| **Push** | **Partially verified** | `device_tokens` = 3 rows on remote (2026-05-21); device delivery still needs your smoke test |

---

## 1. Code baseline

```text
flutter analyze --no-fatal-infos --no-fatal-warnings  → exit 0 (405 info issues, 0 errors/warnings)
flutter test                                         → 108 passed
```

No analyzer errors or warnings with project flags. Info-level lints are mostly `prefer_const_constructors` / `avoid_redundant_argument_values`.

---

## 2. Supabase migration drift (critical)

`npx supabase migration list --linked` shows **divergent history**:

### Applied on remote, no matching local file (on `develop`)

Remote-only versions (May 12 era + recent):

- `20260512070535` … `20260513144900` (many)
- `20260520121347` (remote; local has **`20260520121327`** instead — likely superseded rename)
- `20260520130000` — security corrective
- `20260520140000` — `create_world_full` RPC
- `20260520150000` — daily rewards and events

These exist on the **linked remote** but are **not** in the current `develop` tree (18 local migration files only).

### Local files not applied on remote

- Entire fresh-schema block: `20260515` … `20260519_001`, `20260519_add_rpc`, etc.
- `20260520121327_tighten_device_token_rls.sql`

### In sync (local + remote)

- `20260519144052` … `20260519193753`
- `20260520080241_firebase_storage_and_notification_completion`
- `20260520115334_secure_notification_webhook_secret`

**Verdict:** Do **not** run `supabase db push` until history is reconciled (pull missing remote SQL into repo, or document intentional remote-only migrations). See [PLAN.md](../../PLAN.md) Phase 6.

**Manual (you):** In Supabase Dashboard → Database → Migrations, confirm the three `202605201*` migrations on remote match what you expect in production.

---

## 3. Security (local review + manual dashboard)

### From repo / prior REPORT (still relevant)

- Supabase linter: functions missing `SET search_path`, `SECURITY DEFINER` callable by `anon`
- Weak RLS (`USING (true)`) on `debug_logs`, `league_participants`
- Public **listing** on `avatars` / `post-media` buckets
- `pg_net` in public schema

### Local migration coverage on `develop`

- `20260520121327_tighten_device_token_rls.sql` — **not on remote** (remote has `20260520121347`)
- Corrective migrations `20260520130000`, `20260520140000`, `20260520150000` — **on remote, not in local repo**

### RLS doc status

[rls-audit.md](./rls-audit.md) still lists many tables as “Requires Verification”. Refresh after drift fix.

**Manual (you):**

1. Supabase Dashboard → **Advisors** → Security — export or screenshot findings.
2. SQL editor: confirm `device_tokens` RLS allows insert only for `auth.uid()`.
3. Storage → Policies — check list vs read on public buckets.

---

## 4. UI/UX — static

### Navigation (updated vs old product-gap audit)

Bottom tabs on `develop`: **5 tabs** — Nexus, Explore (`/explore`), Chat, Identity, More — matches PLAN Phase 4 target.

`TabLayout` still uses custom **`_GlassNavBar`** (glass bottom nav), not `VBottomNav` / Forui nav.

### Legacy UI (25 files)

Still reference `GlassPanel`, `GlassSheet`, or `SovereignCard`:

- Core: `glass_panel.dart`, `glass_sheet.dart`, `sovereign_card.dart`, `screen_loading.dart`, `loading_state.dart`
- Worlds: `world_card`, `world_feed_tab`, `world_detail_members`, `chat_preview_panel`, `banner_generator`, …
- Screens: `world_detail_screen`, `alerts_screen`, `ascension_path_screen`
- Nexus: `bento_grid`, `world_invite_section`
- Feed/chat: `post_item`, `chat_input_bar`

`GoogleFonts` — **0 matches** in `lib/` (good).

`BackdropFilter` / `LinearGradient` — ~28 files (many intentional: banners, share cards, splash, image viewer).

### Auth callback

[auth_callback.dart](../../lib/screens/auth/auth_callback.dart) now loads session, resident, and routes to `/`, onboarding, or gate — **not** a placeholder (product-gap #2 outdated).

### “Coming soon” copy (sample)

- `cosmetics_shop_screen.dart`, `world_settings_screen.dart`, `edit_profile_sheet.dart`

### Realtime (updated)

- Posts: `post_provider.dart` subscribes to `posts_realtime`
- Chat: `chat_provider.dart` DM/channel subscriptions
- Notifications: FCM foreground + `PushService` stream (not full Postgres realtime for all tables)

---

## 5. Persistence & repositories

### Repositories present (5)

- `post_repository`, `world_repository`, `profile_repository`, `notification_repository`, `event_repository`

No dedicated repositories yet for: chat messages (service-layer), marketplace, treasury, quests, polls, achievements (per PLAN Phase 7).

### SharedPreferences usage (non-authoritative OK)

| Area | File | Role |
|------|------|------|
| Theme | `theme_provider.dart` | UI preference |
| Search | `search_screen.dart` | Recent searches |
| Settings | `settings_screen.dart` | Local prefs |
| Gate | `the_gate_screen.dart` | Onboarding flags |
| Channels | `world_channel_list.dart` | Channel list cache |
| Offline | `offline_queue.dart` | Legacy queue (deprecated path) |
| Storage | `storage_service.dart` | Debounced string cache |

**Risk:** Chat/posts may still treat cache as primary in some paths — confirm on device after “clear app data” (REPORT handoff).

Repositories grep: no naive `return []` in `lib/repositories/` (good).

---

## 6. Firebase / push

- `PushTokenService` upserts `device_tokens`; debug logging to `debug_logs`
- Edge function + webhook secret migration applied on remote (`20260520115334`)
- **Last known state:** 0 rows in `device_tokens` after login (REPORT 2026-05-20)

**Manual (you):**

1. Install latest **CI APK** from `develop` Actions artifact (or `flutter run` debug).
2. Log in as Immabe, accept notification permission.
3. Supabase Table Editor → `device_tokens` — expect ≥1 row.
4. If empty: check `debug_logs`, or `adb logcat` for Firebase init errors.

---

## 7. Accessibility (not re-tested on device)

Prior [accessibility-audit.md](./accessibility-audit.md):

- Text scale table still “Unknown”
- World rail 44×44 → should be 48×48
- ~25 IconButtons without tooltip (roughly 28 tooltips vs 53 IconButtons in codebase scan)

**Manual (you):** System font size 1.3× and 1.6× on Nexus, Chat, World detail.

---

## 8. Prioritized backlog (P0 → P2)

### P0 — Blockers

| ID | Item | Status |
|----|------|--------|
| S1 | **Migration drift** | Done — see [2026-05-21-migration-reconciliation.md](./2026-05-21-migration-reconciliation.md) |
| S2 | `20260520121327` → `20260520121347` | Done |
| S3 | Supabase Security Advisor | Done — [2026-05-21-security-advisor.md](./2026-05-21-security-advisor.md); enable leaked-password protection in dashboard |

### P1 — High (user-visible / trust)

| ID | Item | PLAN phase |
|----|------|------------|
| U1 | Device UAT: world rail names, tabs, create world, empty states | Phase 1 |
| U2 | Finish glass → Forui migration (25 files + nav bar) | Phase 3 |
| P1 | Push token registration on real device | Phase 9 |
| D1 | Persistence audit after clear-app-data | Phase 7 |

### P2 — Medium

| ID | Item |
|----|------|
| R1 | Refresh [rls-audit.md](./rls-audit.md) table-by-table |
| R2 | Refresh [product-gap-audit.md](./product-gap-audit.md) (tabs, auth, realtime sections outdated) |
| A1 | Accessibility device pass |
| C1 | Remove/replace “coming soon” where features should ship |

---

## 9. Manual checklist (your tasks)

- [x] Supabase **Security Advisor** — 0 errors, 6 WARN types ([security-advisor](./2026-05-21-security-advisor.md))
- [x] Remote migrations `20260520130000`, `140000`, `150000` — restored into repo
- [ ] **Device UAT** (~30 min): use [DEVICE_UAT.md](../DEVICE_UAT.md) checklist
- [x] **League tester blockers (2026-05-22):** channels/search/members — root cause `world_members` + slug join (see DEVICE_UAT)
- [x] **Verifier portal:** `/verifier/login` — profession + achievement review ([VERIFIER_PORTAL.md](../VERIFIER_PORTAL.md))
- [x] **Identity badges:** profession badges from `verifiedRoles` (not shop decorations)
- [ ] **Push smoke:** login → `device_tokens` row → test notification insert
- [ ] **Clear app data** test: posts/chat still recover from Supabase after relaunch
- [ ] Re-test channels/search after APK with slug-join fix (`1d081f0+`)

---

## 10. Release workflow (2026-05-21)

- **Push `develop`** after meaningful batches so CI builds the APK artifact.
- **`main` / Release APK** only after: audits addressed, CI green, your manual device pass, and any fixes.
- **Device UAT** is owner-run at the end; report screen + expected vs actual.

### Agent progress

- [x] Migration reconciliation
- [x] Security advisor documented
- [x] `20260521120000_security_followup` applied to remote
- [x] Product-gap + RLS audits refreshed
- [x] Chat world rail readability
- [x] Glass rename → `VSurfacePanel`, `VLoadingCard`, `_AppNavBar`, `showAppSheet`
- [x] Verifier portal + achievement review queue
- [x] Slug `world_members` join fix (CI `1d081f0`)
- [ ] Full device checklist — [DEVICE_UAT.md](../DEVICE_UAT.md)

---

## Commands reference

```bash
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test
npx supabase migration list --linked
rg "GlassPanel|GlassSheet|SovereignCard" lib --glob "*.dart"
```
