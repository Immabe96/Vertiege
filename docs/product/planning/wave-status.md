# Wave status — 2026-06-07 (updated)

Cross-reference: [`roadmap.md`](../roadmap.md) (7–12), [`perfection-backlog.md`](perfection-backlog.md) (0–6).

**Remote migrations (linked project):**  
`20260531165805_integrations_fts_stream` (fetched from cloud),  
`20260601120000_award_activity_xp_guard`,  
`20260604143000_governance_job_rank_and_profile_label` (profile labels, job/rank governance),  
`20260605150000_subscription_verify_platform` (platform + receipt digest),  
`20260606120000_poll_rpc_season_cohorts` (create_world_poll RPC, season cohort tables),  
`20260607120000_governance_audit_season_challenge_seed` (immediate governance audit + season challenge seed),  
`20260616120000_onboarding_streak_tz`,  
`20260617120000_job_application_notifications`,  
`20260618120000_progression_fairness` (cohort cron, velocity cap, coin ledger, last_active),  
`20260619120000_wave19_voice_governance_commerce` (voice presence, governance notify, coin packs),  
`20260620120000_wave20_identity_achievements` (featured ids, stories, verifier metrics),  
`20260621120000_platform_scheduled_prefs_indexes` (scheduled posts, notification prefs, cursor RPC).

---

## Waves 0–6

| Wave | Status |
|------|--------|
| 0–5 | **Done** — 198 tests green |
| 6 UAT sign-off | **Ready** — [wave-6-signoff-checklist.md](../../operations/uat/wave-6-signoff-checklist.md) + API 30 smoke |

---

## Waves 7–12

| Wave | Status | Delivered |
|------|--------|-----------|
| **7** Voice / Lounge | **Done (code)** | Routing, gates, tools, LiveKit validation, channel seed |
| **8** Composer | **Done (core)** | `PostInput` + `PostCapabilities`; `create_post` RPC; `create_world_poll` RPC with veteran gate |
| **9** Commerce | **Done (MVP)** | `verify_subscription_purchase`, `purchase_cosmetic_with_coins`, pay-to-win SKUs disabled in shop |
| **10** Governance | **Done (core)** | Council queue; proposal + immediate executes in realm audit |
| **11** Progression | **Done (core)** | Season cohorts; auto-seed season challenge; council scope picker on create |
| **12** Release | **Partial** | Forui create-world/shop/settings; post deep links; Campfire mini-bar; invite auto-redeem after auth; `scripts/release_smoke_api30.sh` |

---

## Wave 13 (2026-05-30)

| Item | Status |
|------|--------|
| Deep link matrix doc | Done — [deep-link-matrix.md](../../operations/deep-link-matrix.md) |
| Notification routing tests (all types) | Done — 19 tests |
| RLS + edge rate limits migration | Done — `20260613130000_wave13_rate_limits_rls.sql` (push to remote pending) |
| Edge rate limits (verify + livekit) | Done — code in functions |
| Service role CI grep | Done — `scripts/check_no_service_role_in_lib.sh` |
| Local Supabase integration doc | Done |
| Webhook rotation doc | Done — [store-receipt-hardening.md](../../operations/store-receipt-hardening.md) |
| Funnel analytics + voice breadcrumbs | Done |
| What's new + beta feedback | Done — Remote Config + Settings |
| Tab Worlds label, error states | Done |
| Wave 6 device UAT | **Deferred** — run when ready |
| CI green verify | Ongoing on `develop` |

**Tests:** 210 green locally.

---

## Wave 14 (2026-05-30)

| Item | Status |
|------|--------|
| World detail scroll contract doc | Done |
| World “You are here” subtitle | Done — `WorldHereSubtitleText` |
| Nexus compact shortcuts last-visited order | Done — `NexusShortcutPrefs` |
| Empty states one CTA | Done — challenges, league |
| Haptics (council approve, voice join) | Done |
| Touch targets 48dp | Done — channels, council actions, shortcuts |
| Identity dynamic type (tier row) | Done — `FittedBox` |
| High contrast preview | Done — Settings switch → large text |
| Forui shells (world/chat/thread/campfire) | Already on `FScaffold` / `VHubPage` |
| Feed post highlight | Already in `world_feed_tab` |

**Release APK:** `build/app/outputs/flutter-apk/app-release.apk` (164 MB)

---

## Wave 15 (2026-05-30)

| Item | Status |
|------|--------|
| More → Help & legal | Done — privacy, terms, licenses, beta feedback |
| Settings legal | Moved to More (link tile only) |
| Unified search | Done — Nexus, Identity, Chat → `/search` |
| World manage section anchors | Done — Social / Economy / Governance chips |
| Orphan routes | Done — `/explore/:id/academy`, `/sanctuary` |
| Shop tabs | Cosmetics + Dominions + Coming soon (no P2W tabs) |
| Campfire immersive flag | Done — `campfire_immersive` RC (default off) |
| Feature flag defaults | marketplace/treasury/polls/challenges → true |
| safeBack tests | Done |
| Stale `docs/plan` | Archived → `docs/archive/plan-PERFECTION-BACKLOG.md` |

**Tests:** 212 green locally.

---

## Wave 16 (2026-05-30)

| Item | Status |
|------|--------|
| Gate → first world feed | Done — `routeAfterAuth` lands on first joined world |
| First Steps persistence | Done — `profiles.onboarding_funnel` + sync service |
| Streak timezone-aware | Done — `record_daily_check_in(p_local_date)` + `profiles.timezone` |
| Streak shield UX | Done — daily quests banner + check-in toast |
| Re-engagement push A/B | Done — `re_engagement_push_variant` RC (`calm` / `direct`) |
| Invite funnel analytics | Done — opened / saved / failed / completed events |
| Low-pressure league hide | Done — Nexus bento + compact shortcuts when opt-out |
| Calm ranking UI | Done — league card + league screen percentile copy |
| Social proof copy | Done — season snapshot active-residents line |
| Display title on posts | Done — `author_display_title` + feed label |
| Progression help sheets | Done — treasury, polls (+ glossary lounge/treasury/polls) |

**Migration:** `20260616120000_onboarding_streak_tz.sql` — pushed to Supabase

---

## Wave 17 (2026-05-30)

| Item | Status |
|------|--------|
| Polls path from composer | Done — poll icon → `/polls?create=true` |
| Thread replies Forui | Done — `FScaffold` + `AppErrorState` (existing) |
| Reaction sheet tab-aware | Done — marketplace listing uses tab-aware sheet |
| World dossier collapse | Done — collapsible Knowledge / News / Get started |
| Member list search | Done (pre-existing) |
| Marketplace rep-gated browse | Done — `blockReasonBrowseMarketplace` + quiet gate |
| Job application push | Done — trigger + `reject_world_job_application` RPC |
| Archive world banner | Done — home + feed read-only banner |
| Constitution preview | Done — sheet before join + dossier preview |
| Feed “new posts” pill | Done — tap scroll to top |
| Cross-world DM from profile | Done (pre-existing Message CTA) |
| Adaptive Nexus (RC) | Done — `nexus_bento_segment` |

**Migration:** `20260617120000_job_application_notifications.sql` — pushed to Supabase

**Tests:** 218 green locally.

---

## Wave 18 (2026-05-30)

| Item | Status |
|------|--------|
| `world_members.last_active_at` + touch RPC | Done — channel open, post, join |
| Season cohort weekly cron + MV refresh | Done — migration + pg_cron (staging) |
| Fair matchmaking `match_band` | Done — `ensure_season_cohort_membership` |
| League vs season copy | Done — challenges + season headers |
| Collective challenge labels | Done — “World goal” + world progress copy |
| Daily quest ↔ streak nudge | Done — `StreakDisplay.questNudge` on identity |
| XP velocity flag + soft daily cap | Done — `award_activity_xp` |
| Hall of Ascension season narrative | Done — banner + link to `/season` |
| `featured_achievement_ids` + RPC | Done — `ProfileService` read/set |
| Coin ledger (`coin_transactions`) | Done — `CoinLedgerService` |
| `season_cohort_scores` MV | Done |

**Migration:** `20260618120000_progression_fairness.sql` — pushed to Supabase

**Tests:** 220 green locally (Wave 18 cohort + coin ledger tests added).

---

## Wave 19 (2026-05-30)

| Item | Status |
|------|--------|
| LiveKit reconnect backoff + banner | Done |
| Mic permission rationale sheet | Done |
| Voice channel occupancy | Done — heartbeat RPC + channel list badge |
| Deafen vs mute clarity | Done — Campfire control copy |
| Background audio (iOS/Android) | Partial — `audio`/`voip` background modes + FGS permissions; LiveKit speaker |
| Live receipt verify (edge) | Done — Apple/Google live path in `store_verify_live.ts` (secrets required) |
| `receipt_edge_verify` staging note | Done — ops doc |
| Coin pack IAP RPC | Done — `grant_coin_pack_purchase` + `CoinPackService` |
| Cosmetic try-before-buy | Done — long-press preview sheet |
| Subscription benefits table | Done |
| Restore “already owned” copy | Done — `userFacingPurchaseError` |
| Audit log filter chips | Done — treasury / rank / job / poll |
| Proposal notifications | Done — approve/reject notifies requester |
| Treasury proposed vs executed | Done — audit action split + member proposals restored |
| Poll moderation RPC | Done — `moderate_world_poll` |
| Rank name in governance queue | Done — `world_ranks` join |
| Export audit CSV | Done — share sheet |

**Migration:** `20260619120000_wave19_voice_governance_commerce.sql` — pushed to Supabase

**Tests:** 222 green locally.

---

## Wave 20 (2026-05-30)

| Item | Status |
|------|--------|
| Public profile share URL | Done — `vertiege://residents/:id` + share actions |
| Featured achievements editor | Done — pick 3 verified; `featured_achievement_ids` as TEXT[] |
| Proof upload compression | Done — `flutter_image_compress` before storage |
| Verifier SLA dashboard | Done — `get_verifier_queue_metrics` + review banner |
| Badge PNG CI gate | Done — `validate_assets.ps1` checks core set |
| Trophy case bottom sheet | Done — tap opens sheet on Identity |
| Allies vs following copy | Done — Connections screen headers |
| Verifier compact mode | Done — denser achievement review cards |
| Lounge & Campfire entry | Done — single manage row + picker sheet |
| Achievement stories | Done — optional `achievement_story` on submit |
| World charter templates | Done — create-world FilterChips |
| Season narrative on Nexus | Done — `SeasonNexusBanner` from `global_seasons` |

**Migration:** `20260620120000_wave20_identity_achievements.sql` — pushed to Supabase

**Tests:** 226 green locally.

---

## Wave 21 (2026-05-30)

| Item | Status |
|------|--------|
| Staging Supabase doc | Done — `docs/operations/staging-environment.md` |
| `scheduled_posts` + worker | Done — table + `publish_due_scheduled_posts` + pg_cron |
| `notification_preferences` | Done — table + RPCs; settings sync |
| Index pass | Done — `world_members`, `posts` composites |
| Migration history doc | Done — `docs/operations/migration-history-notes.md` |
| HIBP doc | Done — existing `manual-remaining.md` (Pro gate) |
| App Check notes | Done — `docs/operations/app-check.md` + `supabase_app_check.dart` |
| Integration smoke script | Done — `scripts/integration_supabase_smoke.sh` |
| Image cache policy | Done — `ImageCachePolicy` in `main.dart` |
| Feed keyset pagination | Done — `list_posts_cursor` + repository fallback |
| Realtime per active world | Done — scope on world detail; pause on background |
| Mutation outbox banner | Done — `MutationOutboxSyncBanner` in app shell |
| APK deferred assets | Deferred — Wave 22 optional |

**Migration:** `20260621120000_platform_scheduled_prefs_indexes.sql` — push to Supabase

**Tests:** 228+ green locally.

---

## Wave 22 (2026-05-30)

| Item | Status |
|------|--------|
| Drop `PostComposer` / `CreatePostScreen` | Done — deleted (canonical `PostInput`) |
| Drop `offline_queue.dart` | Done — removed; session clear includes legacy key |
| Drop Boosts/Passes shop UI | Done — shop tabs: Cosmetics + Dominions only |
| Progress hub `/progress` | Done — Quests / World / Season / League tabs |
| Drop wealth tier SKUs | Done — removed from `StoreService` |
| Coin history UI | Done — `/coin-history` + Settings entry |
| High contrast text | Done — shipped label (was preview) |
| Campfire immersive default | Done — RC fallback `true` |
| Adaptive Nexus default | Done — `nexus_bento_segment` fallback `quest_first` |
| Calm ranking default | Done — league bands; no raw `#rank` except top 3 |
| DM entry polish | Done — Direct tab copy + empty state |
| Inline polls | Skipped — RPC still requires poll composer |

**Tests:** 230 green locally.

---

## Waves 13–22 (master plan)

**All 124 research backlog items** are sequenced in **[waves-13-22-master-plan.md](waves-13-22-master-plan.md)** — 10 waves, gates, migrations, and safe drop order (Wave 22).

| Wave | Theme |
|------|--------|
| **13** | Stabilize: UAT deferred; rest shipped in repo |
| **14** | Design shell: Forui migration, tokens, a11y, empty states |
| **15** | Nav & quiet UX: IA, orphans, RC trim, manage anchors |
| **16** | Retention: gate, streaks, invites, calm ranking |
| **17** | Worlds & feed: dossier, jobs notify, polls path, DM |
| **18** | Progression DB: cohort cron, anti-cheat, coin ledger, featured achievements |
| **19** | Voice + governance + live receipts |
| **20** | Identity & achievements + lounge entry |
| **21** | Platform: staging, scheduled posts, indexes, offline, App Check |
| **22** | Drops & consolidation + RC defaults + release regression |

---

## Follow-ups (product / infra)

1. **Store receipt validation** — Edge function deployed (stub → RPC); live Apple/Google verify in **Wave 19**. See [store-receipt-hardening.md](../../operations/store-receipt-hardening.md).
2. **Poll composer** — link-out in **Wave 17**; optional inline in **Wave 22** if RPC ready.
3. **Wave 6** — run sign-off checklist on device / API 30 emulator (**Wave 13** gate).
4. **Wave 12** — `develop` on origin; CI verify + APK green; iOS job uses Xcode 26.1+ for `device_info_plus`. Device UAT + store build remain.
