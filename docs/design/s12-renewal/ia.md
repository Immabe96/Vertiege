# Vertiege Renewal — IA & flow restructure

**Wave S12 · Direction approved 2026-09-18 · Dark-only**

Principle: this is a **re-skin + re-home, never a feature cut**. Every route,
screen, and service that ships today must still ship after the migration. The
tables below are the audit trail for that promise.

Source of truth for visuals: root `DESIGN.md` (Vertiege Renewal, dark-only).
Prototypes: `docs/design/s12-renewal/screens.html`.

---

## 1. Tab map (shell unchanged in count, re-scoped in content)

| Tab | Route | Job (new) |
|-----|-------|-----------|
| **Home** | `/` | Nexus feed first: Today strip (streak, quests, tier), composer, one feed. Bell → unified inbox. |
| **Worlds** | `/worlds` | Gallery, not a rail: featured hero, your worlds (horizontal), trending grid, search. Channels live in world detail. |
| **Chat** | `/chat` | DM-first unified inbox: Direct + Worlds + Campfire sections, presence, unread gold badges. |
| **You** | `/you` | Identity hero, stats, tier progress; hubs: Achievements, Allies, Following, Identity, Settings, Progress. |

---

## 2. Route preservation matrix (every route, new home)

### Shell roots

| Route | Screen | Action |
|-------|--------|--------|
| `/` | `tabs/nexus_screen.dart` | Re-skin: Renewal header (serif wordmark, streak chip, bell), Today strip, composer, feed cards |
| `/worlds` | `tabs/explore_screen.dart` | Re-skin: gallery layout (featured hero → your worlds → trending grid); keep `?world=` redirects |
| `/chat` | `tabs/chat_list_screen.dart` | Restructure: DM-first unified inbox with Direct / Worlds / Campfire sections |
| `/identity` | `tabs/you_screen.dart` | Re-skin: identity hero, stats, tier progress, hubs |

### Auth & onboarding

| Route | Screen | Action |
|-------|--------|--------|
| `/login` | `auth/login_screen.dart` | Re-skin to Renewal tokens (unchanged flows) |
| `/signup` | `auth/signup_screen.dart` | Re-skin (keep social auth + ToS links) |
| `/onboarding` | `onboarding/onboarding_screen.dart` | Re-skin |
| `/the-gate` | `onboarding/the_gate_screen.dart` | Re-skin (keep gate logic + `gateCompleted`) |
| `/auth/callback` | `auth/auth_callback.dart` | Untouched |
| `/verifier/login` | `auth/verifier_login_screen.dart` | Re-skin |
| `/twin-seal` | `twin_seal_setup_screen.dart` | Re-skin (security flow untouched) |
| `/invite/:code` | deep link | Untouched |

### Feed & social

| Route | Screen | Action |
|-------|--------|--------|
| `/notifications`, `/notifications/:id` | `tabs/alerts_screen.dart` + sheet | **Re-home**: becomes the unified inbox reached from Home bell; re-skin |
| `/post/:postId` | post detail | Re-skin |
| `/post/:postId/comments` | `post_comments_screen.dart` | Re-skin |
| `/thread/:messageId` | `thread_screen.dart` | Re-skin |
| `/residents/:id` | `resident_profile_screen.dart` | Re-skin (keep cover/banner + verification tick) |
| `/search` | `search_screen.dart` | Re-skin (keep parallelized member load + filter chips) |
| `/following` | `connections_screen.dart` (following mode) | Re-skin |
| `/allies` | `connections_screen.dart` (allies mode) | Re-skin |

### Chat

| Route | Screen | Action |
|-------|--------|--------|
| `/chat/:roomId` | `chat_room_screen.dart` | Re-skin (channel chat; keep typing, reactions, send-state, voice) |
| `/dm/:roomId` | `chat_room_screen.dart` (DM) | Re-skin |
| `/campfire/:channelId` | `campfire_screen.dart` | Re-skin (keep RC kill switch) |
| — | voice presence/voice services | Preserved; visual pass on voice UI |

### Worlds

| Route | Screen | Action |
|-------|--------|--------|
| `/explore/discover` | `world_discovery_screen.dart` | Merge into Worlds gallery top section or keep as search-results view; re-skin either way |
| `/explore/:worldId` | `world_detail_screen.dart` | Re-skin (banner hero, channel list, member row) |
| `…/settings` | `world_settings_screen.dart` + 3 sections | Re-skin |
| `…/members` | `world_members_screen.dart` | Re-skin |
| `…/marketplace` | `world_marketplace_screen.dart` | Re-skin (keep economy flags) |
| `…/polls` | `world_polls_screen.dart` | Re-skin |
| `…/treasury` | `world_treasury_screen.dart` | Re-skin (admin polish pass) |
| `…/challenges` | `world_challenges_screen.dart` | Re-skin |
| `…/jobs` | `world_jobs_screen.dart` | Re-skin |
| `…/archive` | `world_archive_screen.dart` | Re-skin |
| `…/academy` | `world_academy_screen.dart` | Re-skin |
| `…/sanctuary` | `world_sanctuary_screen.dart` | Re-skin |
| `…/manage` | `world_manage_screen.dart` | Re-skin |
| `…/governance` | `world_governance_screen.dart` | Re-skin |
| `…/:channelName` | `world_channel_screen.dart` | Re-skin |
| `/create-world` | `create_world_screen.dart` | Re-skin (keep tier gate) |
| `/audit-log/:worldId` | `audit_log_screen.dart` | Re-skin |

### You — hubs & economy

| Route | Screen | Action |
|-------|--------|--------|
| `/achievements`, `/achievements/submit`, `/achievements/:category` | `tabs/achievements_screen.dart` + `achievements/*` | **Re-home** as You hub (tab root file becomes hub screen or is removed after routing check); re-skin |
| `/progress` | `progress_hub_screen.dart` | Re-skin (tabs: quests, world, season, league) |
| `/daily-quests` | `daily_quests_screen.dart` | Re-skin |
| `/challenges` | `challenges_screen.dart` | Re-skin |
| `/season` | `season_screen.dart` | Re-skin |
| `/leagues` | `league_screen.dart` | Re-skin |
| `/hall-of-ascension` | `hall_of_ascension_screen.dart` | Re-skin |
| `/ascension-path` | `journey/ascension_path_screen.dart` | Re-skin |
| `/coin-history` | `coin_history_screen.dart` | Re-skin (keep economy flags) |
| `/shop` | `cosmetics_shop_screen.dart` | Re-skin (keep post-first-verified-achievement gating) |
| `/subscription` | `subscription_screen.dart` | Re-skin (keep IAP-paused state) |
| `/verifier/review` | `verification_review_screen.dart` | Re-skin (keep is_verifier gate) |
| `/settings` | `settings_screen.dart` + 3 sections | Re-skin (keep appearance, notifications, prestige sections) |
| `/more` | legacy MoreScreen route | **Remove** (S10.15 follow-through): contents already distributed to You hubs; verify no dead links before deletion |

---

## 3. Service-backed features (no screens, must stay functional)

These are behavior, not screens — the migration must not break them:

| Feature | Services | Renewal note |
|---------|----------|--------------|
| Presence & status | `presence`, `resident_status_service`, `resident_realtime_service` | Green dot + "last seen" in Chat rows |
| Voice | `voice_service`, `voice_presence_service` | Keep in channel/DM composer |
| Typing indicators | `typing_service`, `typing_persistence_service` | Keep |
| Push + local notifications | `push_service`, `local_notification_service`, `firebase_messaging_handlers`, `re_engagement_push_copy` | Keep (quick-reply is a backlog item, not a cut) |
| Achievements realtime & review | `achievement_realtime_service`, `achievement_review_service`, `profile_achievements_service`, `achievement_proof_upload` | Keep under You hub |
| Streak & daily reward | `streak_service`, `daily_reward_service` | Today strip on Home |
| League & leaderboard | `league_service`, `leaderboard_service`, `season_cohort_service`, `season_service` | Progress hub |
| World economy | `treasury_service`, `marketplace_service`, `store_service`, `coin_ledger_service`, `coin_pack_service` | World detail + You hubs (flags unchanged) |
| Governance & moderation | `governance_service`, `council_service`, `rank_service`, `moderation_service`, `moderation_filter`, `access_control` | World admin screens |
| Offline/outbox | `mutation_outbox_service` (+ sync banner) | Keep banner UI, re-skin |
| Preferences | `quiet_hours_service`, `notification_preferences_service`, `chat_density_prefs`, `favorite_channel_prefs`, `last_channel_prefs`, `world_nav_prefs`, `nexus_bento_order`, `nexus_shortcut_prefs`, `contextual_help_prefs`, `world_mute_prefs`, `dm_room_mute_prefs`, `channel_mute_service`, `chat_notification_scope`, `identity_verify_banner_prefs`, `onboarding_funnel_prefs` | All preserved; bento order becomes Today-strip order |
| Security & infra | `supabase_app_check`, `app_check_service`, `secure_storage_service`, `auth_service`, `verification_service`, `admin_access_service`, `backup_service`, `cache_service` | Untouched |
| Analytics & config | `analytics_service`, `analytics_events`, `remote_config_service`, `feature_flags`, `whats_new_service`, `spotlight_service`, `performance_service`, `realtime_status_service`, `crash_reporter` | Untouched |
| Events & RSVP | `event_provider.dart` + `20260724023000_post_event_rsvp.sql` (uncommitted) | Preserved; event cards re-skinned |

---

## 4. Migration waves (implementation order)

Each wave lands on `develop` with `flutter analyze` + `flutter test` green.

| Wave | Scope | Notes |
|------|-------|-------|
| **W1 — Foundation** | `VTokens` rewrite (Renewal dark values, real radius ramp), `VTheme`/`VertiegeForuiTheme` alignment, add Fraunces display font, `VColors` single-accent alignment, `VCard`/`VRaisedCard`, `VButton` pill + gold primary, tab bar restyle | No screen behavior changes |
| **W2 — Shell** | `TabLayout` four tabs, Home header/Today strip/composer, nav icons + labels | |
| **W3 — Home & feed** | Nexus feed cards, unified notifications inbox (re-home alerts), post detail/comments/thread re-skin | |
| **W4 — Chat** | DM-first inbox sections, chat room re-skin, campfire, voice UI pass | |
| **W5 — Worlds** | Gallery (hero/your worlds/trending), world detail + all 13 sub-pages re-skin | Biggest single wave; split per sub-page |
| **W6 — You** | Identity hero, stats, tier progress, Achievements hub, connections switcher, settings | |
| **W7 — Economy, verifier, admin** | Shop, subscription, quests/season/league/challenges, coin history, hall of ascension, verifier screens, audit log | |
| **W8 — Hardening** | Remove legacy (`/more`, dead theme layers, `isDark` ternaries), `prestige_noir_ui.dart` vs `v_prestige_card.dart` merge, docs update, full quality gate + Forui import check | |

## 5. Hard constraints

- **No feature removal.** Anything shipped stays shipped — only relocated or re-skinned.
- Economy flags remain off in beta (S10.16). Campfire kill switch stays (S10.20).
- Government-ID **Identity** tick and achievement **proof** remain separate concepts.
- Vertiege lexicon in all copy: world, resident, achievement, Campfire, Nexus, Identity, Ally, tier.
- Feature code never imports `package:forui/forui.dart` directly (CI gate).
- `service_role` never appears in `flutter-app/lib/` (CI security gate).
