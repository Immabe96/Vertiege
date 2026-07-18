# Vertiege — Production Readiness Audit (Corrected)

**Audited Application:** Vertiege v1.1.0-beta.3+13  
**Platform:** Flutter (Android, iOS, Web, Desktop)  
**Stack:** Flutter + Riverpod + GoRouter + Forui · Supabase · Firebase (FCM, Crashlytics, Analytics, Remote Config, App Check) · LiveKit (voice)  
**Codebase (measured Jul 2026):** ~109K lines of Dart · 569 `lib/` files · 76 test files · ~283 `test`/`testWidgets` cases  
**Date:** July 18, 2026  
**Status:** Corrected after verification against the repo. Prior draft had byte sizes listed as line counts and several false “missing feature” claims.

### Remediation progress (Jul 18, 2026)

| Item | Status |
|---|---|
| Session reset: persist clear on `signedOut`, voice leave, resident service re-init flag | **Fixed in client** |
| Post XP/quest gated on create success; reaction XP only on confirmed success | **Fixed in client** |
| IAP: RC default `receipt_edge_verify=true`; release blocks client stub RPC; edge fails closed without `ALLOW_STUB_RECEIPT_VERIFY` | **Fixed in client + edge deployed** — still need `STORE_RECEIPT_VERIFY_MODE=live` + store secrets in prod |
| Poll votes via `vote_on_post_poll` + poll column guard | **Applied on remote** (`20260718120000`) |
| Economy lockdown (XP/coins/rep/privilege/storage) | **Applied on remote** (`20260717120000` + `20260718130000` overload revoke + `20260718140000` storage/proofs) |
| Moderation: `moderate-content` edge + `checkContentAsync` + RC flag | **Edge deployed**; set `OPENAI_API_KEY` optional for stronger checks |
| World tools sheet scroll; 44pt reply dismiss; Twin Seal reveal-on-tap | **Fixed in client** |
| Feed column select (not `select *`) | **Fixed in client** |
| Icon-only tooltips; 44pt chips; beta empty CTAs; contrast labels | **Fixed in client** |
| Dead `_showSplash` removed | **Fixed in client** |
| Post edit/pin/delete/vote rollback on failure | **Fixed in client** |
| Chat edit/delete outbox enqueue + replay | **Fixed in client** |
| Orphan remote migration `20260702235650` | **Repaired (reverted)**; local `20260703120000` applied |
| Light theme | **Skipped** (product decision) |
| i18n foundation (ARB + gen-l10n + key surfaces) | **Done** |
| God-file splits (post/chat/settings extracts) | **Partial — done for audit debt** |
| E2E / integration smoke + mapper/reaction/l10n tests | **Done** |
| ListTile residual (world events) | **Partial** |
| iOS simulator smoke (`flutter run` iPhone 17) | **App launched successfully** |

**Remote project:** `wjaphoaxalvgjnrwqjwe` — migration list synced through `20260718140000`.

---

## How to read this document

| Severity | Meaning |
|---|---|
| **P0 / Critical** | Ship blocker — exploit, legal/safety, or data integrity risk |
| **P1 / High** | Fix before wider beta; reliable abuse or serious UX/reliability failure |
| **P2 / Medium** | Important debt; schedule soon |
| **P3 / Low** | Cleanup / polish |

**Deploy note:** Migration `supabase/migrations/20260717120000_audit_security_lockdown.sql` patches several economy/RPC holes **in the repo**. Until that migration is applied on the target Supabase project, production/staging may still be exposed. Treat those items as **P0 until applied and verified**.

---

## Table of Contents

- [Executive Summary](#executive-summary)
- [P0 — Ship Blockers](#p0--ship-blockers)
- [P1 — High](#p1--high)
- [P2 — Medium](#p2--medium)
- [P3 — Low](#p3--low)
- [UI/UX](#uiux)
- [Performance](#performance)
- [Architecture & Maintainability](#architecture--maintainability)
- [Test Coverage Gaps](#test-coverage-gaps)
- [Scoring](#scoring)
- [Top Recommendations](#top-recommendations)
- [Already Verified Good / Corrected Myths](#already-verified-good--corrected-myths)
- [Final Verdict](#final-verdict)

---

## Executive Summary

### Strengths

1. Rich social feature set (worlds, chat, voice/Campfire, achievements, tiers, marketplace/jobs behind flags).
2. Cohesive Prestige Noir + Forui design system.
3. Modern stack (Riverpod, GoRouter, Supabase Realtime, Firebase).
4. Mutation outbox + SharedPreferences caches for posts/chat (partial offline).
5. Report UI exists (`ReportSheet` → `ModerationService.submitReport`).
6. Message reactions exist in chat bubbles.
7. Sign out + Delete Account exist in settings.
8. Android Impeller is enabled (`EnableImpeller=true`).
9. Recent client fixes: optimistic post/DM merge, reaction rollback, cold-start viewport, DM bubble contrast.
10. Lockdown migration in-repo for economy RPC privilege (must still be applied remotely).

### Weaknesses (accurate)

1. **Economy / privilege RPCs** were client-abusable; lockdown migration must be **applied and verified** on every environment.
2. **IAP path can still stub-grant** when `receipt_edge_verify` defaults false (Remote Config fallback = false).
3. **Content moderation** is client-only (`ModerationFilter.remoteApiEnabled = false`, tiny English word list).
4. **Large providers/screens** (~1–2K lines) hurt maintainability — real debt, not “40K-line screens.”
5. **Dark-only** theme; light aliases point at dark.
6. **No app i18n**; strings hardcoded.
7. **Critical flows undertested** (auth, post create, chat send, IAP, voice).
8. Session reset gaps: token expiry path may skip persisted clear; voice/Campfire not in `resetUserSessionState`.

---

## P0 — Ship Blockers

### S01. `award_activity_xp` must bind to `auth.uid()`

**Where:** Historical: `20260618120000_progression_fairness.sql`. **Fix in repo:** `20260717120000_audit_security_lockdown.sql` (caller must equal `p_user_id`).  
**Risk if unapplied:** Any authenticated JWT can award XP/tier progress to an arbitrary `p_user_id`.  
**Action:** Apply lockdown migration; confirm with SQL as `authenticated` that cross-user awards raise `Not authorized`.

### S02. `grant_sovereign_coins` client-mintable

**Where:** Granted to `authenticated` in progression fairness. **Fix in repo:** lockdown revokes from `authenticated`/`anon`; `service_role` only.  
**Risk if unapplied:** Users mint coins to themselves via RPC.  
**Action:** Apply + verify `EXECUTE` grants.

### S03. IAP stub / edge verify defaults off

**Where:** Subscription verify RPCs + `FeatureFlags.receiptEdgeVerify` (`RemoteConfigService.getBool` **fallback false**).  
**Symptom:** App can hit stub verify paths; fake/weak receipts may grant `subscription_tier` / coins.  
**Action:** Production Remote Config `receipt_edge_verify=true`; edge `STORE_RECEIPT_VERIFY_MODE=live`; fail closed; never grant from client-callable stub RPC. Confirm client cannot `EXECUTE` stub verify after lockdown.

### S04. `bump_world_member_rep` without authz

**Where:** Marketplace migrations granted `EXECUTE` to `authenticated`. **Fix in repo:** lockdown → `service_role` only (sibling DEFINER RPCs still call it).  
**Risk if unapplied:** Any user can change any member’s rep / standings.  
**Action:** Apply + verify.

### S05. Profile privilege columns writable

**Where:** Self-update paths historically allowed `subscription_tier`, `verified_roles`, `world_standings`. **Fix in repo:** `profiles_guard_privileged_columns()` in lockdown freezes those columns for non–`service_role`.  
**Action:** Apply trigger; attempt client UPDATE of privilege columns and confirm rollback.

### C2. No real content moderation (server-side)

**Where:** `lib/services/moderation_filter.dart` — `remoteApiEnabled = false`, ~15 English terms, TODO for real API.  
**Impact:** Hate/harassment/CSAM-adjacent content not systematically blocked; client filter is bypassable. App-store and trust risk.  
**Action:** Server-side moderation (Edge Function + Perspective / Azure / OpenAI Moderation), image moderation for proofs, RLS/visibility gates for unmoderated content. Client filter = UX only.

---

## P1 — High

### S06. `receipt_edge_verify` defaults false

Even with RPC revoke, client defaults to non-edge path until Remote Config is set. Default true for release builds or fail closed when edge unavailable.

### S07. `create_listing` membership (patched in lockdown)

Lockdown adds `is_world_member` + auth. **Verify applied.** Historical risk: DEFINER insert into any `world_id`.

### S08. Poll votes write poll JSON client-side

**Where:** `post_repository.dart` updates `poll` via table `.update(...)`.  
**Risk:** Bypasses `vote_on_poll_v2`; authors may rewrite tallies if RLS allows post update.  
**Action:** Route all votes through RPC only; tighten RLS so clients cannot patch poll payloads.

### S09 / S10. Storage policies (patched in lockdown)

Verification-proofs were world-readable by all auth users; broad INSERT without path = uid. Lockdown adds owner + verifier SELECT and path-scoped INSERT. **Verify applied.**

### S11. `increment`/`decrement_world_members` client-callable (patched)

Lockdown revokes client EXECUTE and syncs counts via trigger. **Verify applied.**

### R01. `signedOut` skips persisted session clear

**Where:** `app_router.dart` on `AuthChangeEvent.signedOut` calls `resetUserSessionState` only. `AuthService.signOut` clears disk (`clearUserPersistedSessionData`); token expiry / remote logout may not.  
**Action:** Also `await clearUserPersistedSessionData()` on signedOut.

### R02. Same-user re-login / service init flag

**Where:** `app.dart` `_residentServicesInitializedFor`. Cleared mainly on init failure, not reliably on every logout path.  
**Risk:** Push/achievement realtime may not re-init after logout→login same uid.  
**Action:** Null the flag in session reset / signedOut.

### R03. Voice / Campfire not in session reset

**Where:** `session_reset.dart` omits `voiceProvider`; `VoiceService` is static singleton.  
**Risk:** LiveKit room can remain connected under prior account after logout.  
**Action:** `leaveCampfire` / clear voice in `resetUserSessionState`.

### R04. Reaction rollback vs outbox enqueue

Network fail may enqueue mutation while UI rolls back → surprise re-apply on replay. Prefer `.queued()` and keep optimistic UI when queued.

### R05. XP / quest awarded when post create fails

**Where:** `post_provider.dart` — `awardActivityXp('post', 5)` and `onPostCreated()` run **after** the success/fail branches (unconditional).  
**Action:** Gate side-effects on `result.isSuccess` (and decide policy for `queued`).

### H2. Dark-only / weak a11y story

`ThemeMode.dark` only; `VTheme.light` / `lightCommune` alias dark. Custom contrast matrix is not a WCAG substitute.  
**Action:** Real light theme or honest removal of light aliases; system text scaling; Semantics on icon-only controls.

### H3. No internationalization

All user-facing strings hardcoded. Extract ARB / `gen-l10n` before multi-locale expansion.

### H5. Over-fetching posts

`PostService` / `PostRepository` use `.select()` (all columns) for feeds. Prefer explicit feed columns + lean DTO.

### H6. `addComment` swallows increment errors

Silent `catch` around `increment_comment_count` drifts counts and hides failures from Crashlytics. Prefer DB trigger; log failures.

### H8. Client permissions ≠ RLS

`PermissionService` / `WorldPermissions` are UX hints only. Enforcement must be RLS/RPC. Audit divergence.

### C6. `VoiceService` all-static

Hard to test; lifecycle races with `_disposed`; leaks across sessions (see R03). Convert to injectable / Riverpod-owned service.

### U01. World tools sheet overflows

Non-scrolling column in admin tools sheet clips on small phones → wrap in scroll view.

### U02. Reply dismiss hit targets ~16px

Comment sheet / chat input cancel reply IconButtons fail ~44pt a11y minimum.

---

## P2 — Medium

### S12. `refresh_season_cohort_scores` DoS (patched in lockdown)

Revoke client EXECUTE; cron/`service_role` only. **Verify applied.**

### R06. Concurrent `loadPosts` / `loadResident` races

Overlapping loads can apply stale snapshots. Use generation token / single-flight.

### R07. Offline edit/delete DM has no outbox

Sends can queue; edit/delete revert on fail. Enqueue and replay.

### R08. Poll / pin / delete / comment fire-and-forget

Unlike reactions, several mutations lack rollback / sync-error badge.

### H1 / A4. Freezed underused

`freezed_annotation` present; **0** `*.freezed.dart`; ~21 `*.g.dart`. Large hand-written `copyWith` on Post / ResidentState. Migrate models gradually.

### H4. Offline is partial, not absent

SharedPreferences caches posts/chat + mutation outbox exist. Not a durable local DB (Isar/Hive/SQLite) for worlds/history. Improve cache freshness and conflict handling rather than claiming “no offline.”

### H7. Magic standing thresholds

`PermissionService` hardcodes standing cutoffs. Move to Remote Config / single config module.

### M1. Test gaps on critical flows

Auth, post create, chat send, voice, IAP largely untested. Utils/config covered better.

### M2. Feed scroll optimization incomplete

Some `ListView.builder` usage; limited evidence of systematic `RepaintBoundary` / keep-alive strategy for heavy feed items.

### M4. Multiple `addPostFrameCallback` on cold start

Nexus / empty-state patterns can contend for first-frame work. Prefer provider-driven init where possible.

### M5. Analysis options thin

Missing `riverpod_lint` / `discarded_futures` / stronger recommended set.

### M7. Hard build version gate

Outdated-build banner can lock users with little grace/offline fallback. Soften with grace period + cached check.

### M8. Loading UX inconsistency

Some screens use skeletons; Nexus still often spinner-centric. Align on shimmer/skeleton for feed/worlds/chat.

### M9. Lexicon drift in copy

Hardcoded strings mix “world” / “community” etc. Centralize copy (also helps i18n).

### M10. Infinite scroll race

Nexus near-bottom trigger can double-fire under fast scroll; harden with `isLoadingMore` + cooldown.

### U03–U06. Contrast, semantics, chips, beta empties

Low-contrast `mutedDim` 10px labels; unlabeled icon buttons; dense chips &lt;44pt; jobs/marketplace locked empties without clear exit CTA.

### U07. Twin Seal secret in plaintext UI

2FA secret shown as text (screenshot risk). Prefer QR-only + reveal-on-tap.

### A1 / A2 / A5 / A6. Structure debt

~97 flat services; mixed `@Riverpod` vs legacy notifiers; Material/Forui/V* mix; heavy `app.dart` wiring.

### A3. Repository layer incomplete (not “only WorldRepository”)

**Present:** `post_repository`, `world_repository`, `profile_repository`, `notification_repository`.  
**Gap:** Chat and other domains still talk to Supabase from services/providers. Expand repos; stop claiming only one exists.

### Router size (demoted from Critical)

`app_router.dart` ~646 lines, ~70 imports — large and should be split by domain, but not a legal/security blocker. Prefer lazy route modules.

### Markdown / XSS (demoted)

`flutter_markdown` used in chat/constitution. **Mobile Flutter does not execute HTML/JS like a browser.** Still sanitize for **web** target and strip dangerous constructs server-side. Not a mobile P0 XSS claim.

### Outbox visibility (demoted from Critical)

Failed posts set `SyncStatus.error` and `"Failed to post - tap to retry"`; DMs show `"Failed to send · tap to retry"`; `VSyncBadge` exists. Gaps remain (discoverability, background retry polish) — P2, not “silent with no UI.”

---

## P3 — Low

### L1. Dead `_showSplash = false`

Dead splash branch in `app.dart`. Remove.

### L2. Deceptive `light` theme aliases

Remove or implement real light themes.

### L3. Inconsistent error-facing helpers

Standardize on one failure type / user-facing mapper.

### L5. `.env.template` labeling

Mark which keys are public vs secret vs optional.

### U5. Nav icon migration polish

Finish Forui icon weight consistency.

### U7. Feed sort discoverability

Make sort control more obvious without cluttering hero chrome.

### P6. Fonts loaded in `main`

`VFonts.ensureLoaded()` blocks TTFF; load critical subset first.

---

## UI/UX

| ID | Issue | Sev |
|---|---|---|
| U1 | Dark-only limits outdoor/a11y use | P1 |
| U2 | Empty states sometimes lack CTAs | P2 |
| U3 | Onboarding / lexicon still thin for first-run | P2 |
| U01 | World tools sheet overflow | P1 |
| U02 | Reply dismiss hit targets | P1 |
| U03–U06 | Contrast, semantics, chip size, beta dead-ends | P2 |
| U07 | Twin Seal secret plaintext | P2 |

**Removed inaccurate claims:** “No confetti” (tier celebration canvas exists), “No haptics” (used widely via `Haptics` / `HapticFeedback`), “No Delete Account / Sign out”, “No message reactions”, “No report flow” (sheet + submit exist; admin queue maturity is separate).

---

## Performance

| ID | Issue | Sev | Notes |
|---|---|---|---|
| ~~P1 Impeller unknown~~ | **Removed** | — | Android `EnableImpeller=true` verified |
| P2 | `const` on V* facades incomplete | P2 | |
| P3 | Animations without RepaintBoundary | P2 | |
| P4 | Fat `PostState` rebuilds feed listeners | P2 | Prefer `.select` / split notifiers |
| P5 | Full-res images in feed | P2 | Supabase image transforms / sized URLs |
| H5 | `.select()` over-fetch | P1 | |

---

## Architecture & Maintainability

### God providers / large screens (corrected sizes)

| File | Lines (wc -l) | Notes |
|---|---|---|
| `chat_provider.dart` | ~1,921 | Split rooms / messages / typing |
| `post_provider.dart` | ~1,538 | Split feed / compose / reactions |
| `world_settings_screen.dart` | ~1,516 | Largest screen — still not 60K |
| `settings_screen.dart` | ~1,476 | |
| `search_screen.dart` | ~1,394 | |
| `resident_provider.dart` | ~1,235 | |
| `chat_room_screen.dart` | ~1,240 | Prior audit listed **40,894** — that was **bytes** |
| `world_detail_screen.dart` | ~1,090 | |
| `world_channel_screen.dart` | ~1,022 | |
| `app_router.dart` | ~646 | |

**Severity:** P1 maintainability (not a security P0). Target: screens &lt; ~400–600; providers split by concern; feature folders.

---

## Test Coverage Gaps

| Area | Adequate? |
|---|---|
| Auth | ❌ |
| Post create / reactions / outbox | ❌ / partial |
| Chat send / edit / reactions | ❌ / partial (unread math) |
| Voice / LiveKit | ❌ |
| IAP / subscription verify | ❌ |
| Settings / delete account | ❌ |
| Navigation redirects | Partial |
| Utils / config | Better |

~283 tests vs ~109K LOC is thin for a social client. Prioritize integration tests: signup → join → post → chat → purchase.

---

## Scoring

| Category | Score | Notes |
|---|---|---|
| UI Design | **7.5/10** | Strong Prestige Noir; dark-only limits reach |
| UX | **6.5/10** | Better than prior draft claimed (retry UI, celebrations, haptics); onboarding/a11y gaps remain |
| Performance | **6.5/10** | Impeller on; still fat providers + over-fetch |
| Accessibility | **3.5/10** | Dark-only, small hit targets, incomplete Semantics |
| Features | **7.5/10** | Broad surface; moderation + economy gates incomplete |
| Security | **3.5/10 until lockdown applied & IAP live**; **5.5/10 after apply + verify** | Concrete RPC holes dominate over vague “RLS unknown” |
| Architecture | **5.5/10** | Sound stack; 1–2K god files; partial repos |
| Testing | **5.0/10** | Volume without critical-path coverage |
| Production readiness | **3.5–4.5/10** | Beta justified until RPC lockdown verified + moderation + IAP fail-closed |

---

## Top Recommendations

| # | Action | Effort | Why |
|---|---|---|---|
| 1 | **Apply + verify** `20260717120000_audit_security_lockdown.sql` on all Supabase envs | 1–2 days | Closes XP/coin/rep/privilege exploits |
| 2 | **IAP fail-closed** — `receipt_edge_verify=true`, live store verify, no client stub grants | 3–5 days | Prevents paid-tier theft |
| 3 | **Server-side content moderation** + image checks | 1–2 weeks | Safety / store compliance |
| 4 | Fix **session reset** (persisted clear on signedOut, voice leave, init flag) | 1–2 days | Account bleed / stuck Campfire |
| 5 | Gate **post XP/quest** on create success; poll votes via RPC only | 2–3 days | Economy + integrity |
| 6 | Split **post/chat providers** and largest screens | Ongoing | Unlocks safe iteration |
| 7 | Integration tests for top 5 journeys | 1–2 weeks | Regression shield |
| 8 | Light theme or remove fake light aliases + 44pt targets / Semantics | 1–2 weeks | A11y / reach |
| 9 | Column-selective feed queries + image transforms | 1 week | Bandwidth / scroll |
| 10 | Expand repos (chat) + rate limits server-side | 1 week | Abuse resistance |

---

## Already Verified Good / Corrected Myths

| Prior claim | Verdict |
|---|---|
| Screens are 34K–60K **lines** | **False** — those were **byte sizes**; real screens ~1.0–1.5K lines |
| Impeller not enabled | **False** — Android meta-data `EnableImpeller=true` |
| No Delete Account / Sign out | **False** — both in `settings_screen.dart` |
| No confetti / celebrations | **False** — `tier_celebration.dart` confetti canvas |
| No haptic feedback | **False** — widespread `Haptics` / `HapticFeedback` |
| Only `WorldRepository` exists | **False** — also post, profile, notification repos |
| No message reactions | **False** — chat bubble reactions + `toggleReaction` |
| No report flow | **False** — `ReportSheet` + `ModerationService.submitReport` |
| Notification snack id set unbounded leak | **False** — 30s `Timer` eviction |
| Connectivity never cancelled | **False** — cancelled in `dispose` |
| No offline at all | **Overstated** — prefs cache + outbox; not full offline-first |
| Outbox failures invisible | **Overstated** — retry copy + sync badge exist |
| User blocking missing | **Partial** — ally `blockResident` exists; may need broader block/mute UX |
| Mobile stored XSS via markdown | **Overstated** for Flutter mobile; still relevant for **web** |

### Already in good shape (client)

- No `service_role` key in Flutter client (keep CI gate).
- DM/channel/thread in-flight message merge; post optimistic merge + server id swap.
- Reaction rollback on hard failure; quest claim no longer invents XP on RPC fail (post-create XP still ungated — R05).
- Auth `signOut` clears persisted session + in-memory providers.
- Cold-start Chat viewport + DM bubble contrast fixes.
- `add_league_xp` binds `auth.uid()` (do not regress).

---

## Missing Features & Enhancements (accurate)

| Feature | Priority | Notes |
|---|---|---|
| Admin moderation queue / dashboard | High | Client report exists; ops tooling incomplete |
| Server-side rate limits | High | Client `RateLimiter` only |
| Broader block/mute (beyond ally block) | High | Confirm product coverage |
| Data export (GDPR) | Medium | Delete account exists; export separate |
| Search within conversations | Medium | |
| Voice messages | Medium | |
| Push quick-reply | Medium | |
| Stronger offline (Isar/SQLite) | Medium | |
| Light theme | Medium | |
| Stories / ephemeral | Low | Scope risk |

---

## Final Verdict

**Vertiege is feature-rich and visually strong, but not production-ready until economy/RPC lockdown is applied and verified, IAP verification fails closed, and server-side moderation exists.**

### True pre-launch blockers

1. **Supabase economy privilege** — apply lockdown migration everywhere; re-test as a normal authenticated user.  
2. **IAP / receipt verification** — no stub grants in production.  
3. **Server-side moderation** — replace the 15-word client list as the real control plane.

### Important but not “40K-line crisis”

God providers/screens at ~1–2K lines are serious maintainability debt and should be split, but the prior draft’s byte-as-line metrics invented a false Critical. Prefer security + session integrity first.

### Estimated path

- **1–2 weeks:** Apply/verify lockdown, IAP fail-closed, session/voice reset, R05 XP gate, poll RPC.  
- **+2–4 weeks:** Moderation API, a11y/hit targets, provider splits, critical-path tests.  

**Team shape:** 1–2 Flutter + 1 backend (Supabase/Edge) + QA for store-bound beta.

---

*Corrected July 18, 2026. Merges verified codebase checks with the Jul 17 in-depth security/reliability audit. Remove or re-open P0 items only after remote migration proof, not after seeing files on disk alone.*
