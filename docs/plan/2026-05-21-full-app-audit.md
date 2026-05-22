# Vertiege — Full App Audit (2026-05-21)

Scope: Flutter client (`lib/`), routing, Riverpod state, services, Supabase + Firebase backends.  
Methods: static analysis (`dart analyze`), route grep, screen review, **Supabase security advisors** (project `wjaphoaxalvgjnrwqjwe`), Firebase environment check.

---

## Executive summary

| Area | Critical | High | Medium | Low |
|------|----------|------|--------|-----|
| Navigation / bugs | 2 | 4 | 6 | 5 |
| Duplicate / misleading UI | 0 | 5 | 8 | 4 |
| Data / services accuracy | 1 | 3 | 5 | 3 |
| Supabase security (MCP) | 0 | 2 | 30+ RPC warnings | 3 |
| Code health | 0 | 0 | 4 warnings | many info |

**Top 5 fixes before next APK:** (1) Nexus Challenges bento → `/challenges`, (2) `world_hub_tab` `/market` → `/marketplace` or delete dead widget, (3) Identity Following/Allies → real screens not `/search`, (4) Revoke anon EXECUTE on sensitive RPCs (`add_league_xp`, treasury, `process_league_reset`), (5) Forui migration pass on high-traffic legacy screens.

---

## P0 — Critical (ship blockers)

### P0-1 Wrong route: Nexus Challenges card opens Daily Quests
- **File:** `lib/screens/tabs/nexus_screen.dart` (~440–443)
- **Issue:** `BentoCard(child: ChallengesCard(), onTap: () => context.push('/daily-quests'))` overrides the card; `ChallengesCard` itself correctly uses `/challenges`.
- **Impact:** Users tap “Challenges” and land on Daily Quests — wrong feature, feels broken.
- **Fix:** Remove outer `onTap` or set `onTap: () => context.push('/challenges')`.

### P0-2 Broken route: World hub “Market” path does not exist
- **File:** `lib/widgets/worlds/world_hub_tab.dart` (line 62)
- **Issue:** Pushes `/explore/$worldId/market` but router defines `marketplace` (`app_router.dart`).
- **Impact:** 404 / empty route if this widget is ever wired in.
- **Note:** Widget appears **unused** (no imports). Still fix or delete to avoid future regression.
- **Fix:** Change to `/explore/$worldId/marketplace` or remove `world_hub_tab.dart`.

### P0-3 Supabase: anon can execute privileged SECURITY DEFINER RPCs
- **Source:** Supabase MCP `get_advisors` (security), project `wjaphoaxalvgjnrwqjwe`
- **Examples:** `add_league_xp`, `donate_to_treasury`, `withdraw_from_treasury`, `process_league_reset`, `create_world_from_template`, `vote_on_poll`, `award_rep_milestone_xp`
- **Impact:** Unauthenticated clients could invoke RPCs if they obtain the anon key (standard in mobile apps).
- **Fix:** Migration: `REVOKE EXECUTE ON FUNCTION ... FROM anon` for write/privileged functions; keep read helpers as needed; validate `auth.uid()` inside DEFINER functions.

### P0-4 Achievement AI labels vs behavior
- **Files:** `lib/services/ai_verification_service.dart`, `lib/state/achievement_provider.dart`, UI chips in `achievement_proof_sheet.dart` / legacy `achievement_card.dart`
- **Issue:** Service always returns `autoApproved: false`, `confidence: null`, notes say manual review — but UI may still show “AI-Verified” paths from old copy; provider still has `shouldAutoVerify` at ≥0.75 (never triggers).
- **Impact:** Misleading “AI verification” UX; users expect faster approval.
- **Fix:** Align copy to “Submitted for review”; wire Genkit/Firebase AI Logic or Edge Function for real vision; or hide AI chips until implemented.

---

## P1 — High

### P1-1 Identity: duplicate entry points to same destinations
- **File:** `lib/screens/tabs/identity_screen.dart`
- Honour chips → `/achievements` (line ~490) **and** VSectionList “All achievements” → `/achievements` (~768).
- **Fix:** Keep chip + one list link; remove duplicate row or rename chip to “Open trophy case”.

### P1-2 Identity: Following and Allies both open Search
- **File:** `identity_screen.dart` (~772–780)
- **Issue:** “Following (N)” and “Allies (N)” both `context.push('/search')` — inaccurate navigation.
- **Fix:** `/residents?tab=following` or dedicated following/allies sheet; use `ally_provider` list UI.

### P1-3 Identity: XP shown in multiple formats on one scroll
- TrophyCase `totalXp`, tier bar “segment XP”, footer “total XP”, `_PerksCard` multiplier — not wrong but dense; Wall of Honour chip + TrophyCase both surface achievement counts.
- **Fix:** Single “Progress” card (tier bar + one XP line); move perks to collapsed section.

### P1-4 Nexus: duplicate Daily Quests taps
- DailyQuestCard bento **and** Challenges bento wrongly → daily quests; League/Season cards OK.
- **Fix:** One quest entry on Nexus; link Challenges correctly (P0-1).

### P1-5 More tab vs Identity vs Nexus overlap
- **Files:** `more_screen.dart`, `identity_screen.dart`, `nexus_screen.dart`
- Achievements, league, season, daily quests, hall, shop appear in 2–3 places.
- **Fix:** Product map: Nexus = activity feed; Identity = profile/honour; More = settings + deep links only.

### P1-6 `use_build_context_synchronously` in router redirect
- **File:** `lib/router/app_router.dart` (~648)
- **Fix:** Guard with `context.mounted` or avoid context in async redirect.

### P1-7 Settings: async context guards
- **File:** `lib/screens/settings_screen.dart` (multiple ~198–448)
- **Fix:** Use `if (!context.mounted) return` after awaits.

### P1-8 Storage buckets allow public listing
- **Supabase advisor:** `avatars`, `post-media` broad SELECT policies
- **Fix:** Tighten policies to object-level read without list; see [remediation](https://supabase.com/docs/guides/database/database-linter?lint=0025_public_bucket_allows_listing).

### P1-9 Auth: leaked password protection disabled
- **Supabase advisor:** `auth_leaked_password_protection`
- **Fix:** Enable in Supabase Auth settings (**Pro+ only**). On **Free**, use minimum length + required character classes; accept advisor warning until upgrade.

---

## P2 — Medium

### P2-1 Forui migration incomplete (~35+ screens still raw Scaffold/AppBar)
- Examples: `league_screen`, `chat_room_screen`, `cosmetics_shop_screen`, `resident_profile_screen`, `season_screen`, `challenges_screen`, `daily_quests_screen`, journey screens.
- **Fix:** Phased migration: hub screens first (league, challenges, quests, profile).

### P2-2 Dead / orphaned widgets
- `lib/widgets/achievements/achievement_grid.dart` — not imported after rebuild
- `lib/widgets/worlds/world_hub_tab.dart` — no imports, wrong routes
- **Fix:** Delete or wire intentionally.

### P2-3 `dart analyze` warnings (unused code)
- `post_repository.dart` `_isUuid` unused
- `create_world_screen.dart` unused import + `_requiredTierLevel`
- `post_provider.dart` `_mergePosts` unused
- **Fix:** Remove or use.

### P2-4 Silent error swallowing in providers
- **Files:** `chat_provider`, `resident_provider`, `achievement_provider`, `post_provider` — many `catch (_) {}`
- **Impact:** Empty UI with no error state (white lists, 0 XP with no explanation).
- **Fix:** Surface `LoadState.error` / snackbars for user-visible failures.

### P2-5 Moderation / AI stubs
- `ai_verification_service.dart` — TODO real vision API
- `moderation_filter.dart` — TODO real API
- **Fix:** Backend pipeline doc + feature flag off until live.

### P2-6 Identity not on `VHubPage`
- Still custom scroll + mixed `VButton` / `FilledButton` / `ListTile` sign-out
- **Fix:** Align with achievements/world discover pattern.

### P2-7 World detail FEED tab may still duplicate stats if reintroduced
- Post-rebuild: verify APK — stats strip once under hero; Manage vs More split maintained.
- **Fix:** UAT checklist per tab.

### P2-8 Firebase Android bundle ID unknown
- **Firebase:** Android/iOS bundle `com.vertiege` — register in Firebase Console; `google-services.json` in repo
- **Fix:** Register Android package in Firebase console; verify `google-services.json`.

### P2-9 Gemini ToS not accepted / billing off
- Blocks Firebase AI Logic experiments in console — not a runtime bug if not used yet.

### P2-10 Duplicate theme tokens
- `design_system.dart`, `colors.dart` — TODO migrate to `v_tokens` / `VColors`
- **Fix:** Lint rule or batch rename.

---

## P3 — Low / polish

- Analyzer `prefer_const_constructors` / `avoid_redundant_argument_values` across screens (100+ info)
- `audit_log_screen.dart` — missing braces in if statements (style)
- Achievement submit: duplicate header + footer submit buttons (index screen)
- `pg_net` in public schema (Supabase advisor)
- Campfire / thread / search — minor const hints
- Image asset pipeline: 64 manifest items still `pending` — badges fall back to icons

---

## Backend audit (Supabase MCP)

**Project:** Immabe96's Project (`wjaphoaxalvgjnrwqjwe`), ACTIVE_HEALTHY, Postgres 17.

### Security advisors (summary)
| Lint | Count | Action |
|------|-------|--------|
| `anon_security_definer_function_executable` | ~25 functions | Revoke anon EXECUTE on writes/admin |
| `authenticated_security_definer_function_executable` | ~25 functions | Audit which need authenticated-only |
| `public_bucket_allows_listing` | 2 buckets | Narrow storage policies |
| `extension_in_public` | pg_net | Move schema |
| `auth_leaked_password_protection` | 1 | Enable |

Full JSON: local MCP output `fc726afe-37eb-484c-85ae-b0ac0e9dcb2b.txt` (session artifact).

### Performance advisors
Large set (290KB) — typical missing indexes / RLS initplan issues. Run `get_advisors(performance)` in a dedicated DB pass after security P0.

---

## Firebase audit (MCP)

| Check | Status |
|-------|--------|
| Project ID | `veritage` |
| Remote Config / FCM / Crashlytics | Used in `main.dart`, `remote_config_service.dart` |
| Android bundle | Needs verification |
| Billing | Disabled (OK for dev) |

No Crashlytics pull run (optional follow-up via `crashlytics_get_report`).

---

## Navigation matrix (verified issues)

| From | Route pushed | Router has? | OK? |
|------|----------------|-------------|-----|
| Nexus Challenges bento | `/daily-quests` | yes | **Wrong target** |
| ChallengesCard | `/challenges` | yes | OK (overridden) |
| world_hub_tab Market | `/explore/:id/market` | **no** (`marketplace`) | **Broken** |
| world_detail Manage | `/explore/:id/marketplace` | yes | OK |
| Identity Following/Allies | `/search` | yes | **Misleading** |
| resident_profile Message | `/dm/:roomId` | yes | OK (fixed prior) |

---

## Remediation plan (phased)

### Phase 0 — Quick wins (1–2 days)
1. ~~Fix Nexus Challenges `onTap` → `/challenges`~~ ✅
2. ~~Fix `world_hub_tab.dart` marketplace path~~ ✅
3. ~~Spotlight card → `/residents/:id`~~ ✅
4. ~~world_archive URL interpolation~~ ✅
5. ~~Identity: Following/Allies → `/search?mode=`; allies `?tab=` scroll; dedupe REP + achievements link~~ ✅
6. ~~Query params: `?q=` search, `?post=` world feed highlight, notification deep links~~ ✅
7. ~~Achievements: single submit CTA (header); removed footer stats line~~ ✅
8. ~~Session reset on sign-out; auth → GoRouter refresh; ally load at startup~~ ✅
9. ~~Post provider: rep only on own new posts~~ ✅
10. ~~Remove unused `achievement_grid.dart`~~ ✅
11. Clean remaining `dart analyze` warnings (deferred)
12. ~~Delete dead `world_hub_tab.dart`, `achievement_card.dart`~~ ✅
13. ~~Provider load errors: resident, achievements; identity error UI~~ ✅

### Phase 1 — Security & data trust (3–5 days)
1. ~~Supabase migration `20260523120000_phase1_rpc_and_notifications` (applied remote)~~ ✅
2. ~~Storage listing hardening + drop legacy `avatars public read` / `post-media public read` (remote)~~ ✅
3. ~~`20260524130000` + `20260524130500` revoke anon/PUBLIC write RPC EXECUTE (remote)~~ ✅
4. Leaked-password protection — **Pro+ only** (skip on Free; use min length + character rules) → `docs/plan/MANUAL_REMAINING.md`
5. ~~Provider errors: league trackXP, notifications load, award_activity_xp fail-closed~~ ✅
6. ~~Achievement cloud sync on load; mention RPC; league unranked; startup dedupe~~ ✅
7. ~~Remove hardcoded superuser email; lock `process_league_reset` from app~~ ✅

**Your manual checklist:** `docs/plan/MANUAL_REMAINING.md`

### Phase 2 — UX consolidation (1 week)
1. ~~**Identity** pass 2: progress card, collapsible perks, VHubPage loading, session sign-out~~ ✅
2. ~~**Nexus** bento IA: remove FeedPreviewCard; slim header~~ ✅
3. ~~**More** screen: account-only~~ ✅
4. ~~Forui: league, challenges, daily quests, resident profile, chat room header~~ ✅

### Phase 3 — Features & accuracy (in progress)
1. ~~Achievement proof: `autoVerificationEnabled` flag; honest review copy; no auto-approve path~~ ✅
2. ~~Chat DM load errors surfaced; deep-link `context.mounted` on notifications~~ ✅
3. ~~Dead `feed_preview_card.dart` removed~~ ✅
4. Real AI vision + moderation API — not started
5. Supabase performance advisor pass — not started

### Phase 3 — Features & accuracy (2+ weeks)
1. Real achievement proof AI (Firebase AI Logic / Supabase Edge + vision)
2. Moderation API integration
3. Supabase performance advisor remediation
4. Asset pipeline: promote generated badges per `docs/assets/image-manifest.json`
5. Android Firebase app registration + FCM E2E test
6. Manual UAT script (all tabs, DM, world sub-routes, submit proof)

### Phase 4 — Tech debt
1. Remove `design_system.dart` / `colors.dart` bridges
2. Delete dead widgets; consolidate achievement_card vs list_tile
3. Test coverage for router table and provider error paths

---

## Pass 2 audit (2026-05-23)

**Verified on device:** `com.vertiege` 1.0.0-beta.4, Google sign-in OK, **15** `device_tokens` rows.

| Finding | Severity | Pass 2 action |
|---------|----------|---------------|
| Following/Allies → generic Search | Medium | **Fix:** `/following`, `/allies` hub screens |
| Unused imports (4) | Low | **Fix:** removed |
| `google_sign_in` unused (OAuth via Supabase) | Low | **Fix:** removed from pubspec |
| ChallengesCard double tap | Low | **Fix:** bento `onTap` only |
| World load silent failure | Medium | **Fix:** `worldProvider.loadError` + Explore banner |
| Ally load silent failure | Medium | **Fix:** `allyProvider.loadError` |
| 36 auth + 10 anon DEFINER WARN | Medium | Intentional; review per-function later |
| Performance advisor (RLS/index) | Medium | Deferred — dedicated DB pass |
| 61 pending badge assets | Low | Deferred |
| Forui migration incomplete | Low | Deferred |
| Theme bridge (`design_system.dart`) | Low | Deferred |
| Real AI / moderation API | Medium | Deferred (flag off) |

---

## Manual UAT checklist (post-fix APK)

- [ ] Nexus → Challenges → `/challenges` screen
- [ ] Nexus → Daily Quests → `/daily-quests`
- [ ] World → Manage → Marketplace, Treasury, Polls, Challenges
- [ ] Achievements → category → proof sheet → upload → pending state
- [x] Identity → Following / Allies → `/following`, `/allies` (Pass 2)
- [ ] Profile → Message → DM room (no white screen)
- [ ] League XP non-zero when season active
- [ ] Sign out / gate / verifier routes unaffected

---

## References

- Prior rebuild: achievements + world detail (2026-05-22)
- Screen rebuild plan: `docs/plan/2026-05-22-screen-rebuild-plan.md`
- Image pipeline: `docs/assets/CODEX_START_HERE.md`
- Supabase linter: https://supabase.com/docs/guides/database/database-linter
