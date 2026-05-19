# Vertiege Full App Audit

**Date:** 2026-05-19
**Auditor:** OpenCode
**Branch:** main
**Scope:** Full codebase audit per docs/opencode/full-app-audit-and-overhaul-plan.md

---

## P0: Blocks Core App Use

### P0-1: Starter World Entry Redirects to Nexus

- **Files:** `lib/screens/onboarding/onboarding_screen.dart`, `lib/screens/tabs/tab_layout.dart`, `lib/services/world_service.dart`, `lib/state/world_provider.dart`
- **Root cause:** Onboarding auto-joins `neon-district` and `crystal-shore`, but the world entry flow may not properly set resident membership state or the world access guard may reject entry. If Supabase is not configured or RLS policies block reads, the join silently fails and the user is redirected back.
- **User impact:** New users cannot enter their first world after onboarding -- the app loops back to Nexus.
- **Proposed fix:** Trace the full flow: onboarding complete -> world join -> membership state -> world entry -> access guard. Ensure `WorldService.joinWorld()` succeeds (or uses outbox retry), `WorldProvider` reflects membership, and `WorldAccessGuard` permits entry for default worlds. Add explicit error UI when join fails.
- **Verification:** New account completes onboarding, taps starter world, enters without redirect. Membership survives app restart.

### P0-2: Nexus/World Feed Produces Supabase 42501 Permission Errors

- **Files:** `lib/services/post_service.dart`, `lib/repositories/post_repository.dart`, `supabase/migrations/20260515_complete_fresh_schema.sql`, `supabase/migrations/20260518_forui_hybrid_persistence_overhaul.sql`
- **Root cause:** RLS policies on `posts` table may not correctly allow authenticated users to read feed rows for worlds they are members of. Policies may be missing, incorrectly scoped, or overridden by later migrations.
- **User impact:** Feed appears empty or errors for authenticated users who should have access.
- **Proposed fix:** Audit all RLS policies on `posts`, `comments`, `reactions`, `bookmarks`, `world_memberships`, `channels`, and `channel_reads`. Verify that authenticated users can read rows for worlds they joined. Add explicit SELECT policies for member-scoped reads.
- **Verification:** Authenticated user joins a world, creates a post, refreshes, and sees the post without 42501.

### P0-3: Default World/Channel Seed Data Incomplete

- **Files:** `lib/services/world_service.dart:329-395` (`createDefaultChannels`), `lib/config/tiers.dart:142-328` (`worldsConfig`), `lib/utils/world_foundations.dart`
- **Root cause:** `createDefaultChannels()` creates channels with brief placeholder descriptions but does NOT populate `foundationMarkdown` content. Channel models have no `foundationMarkdown` field. The `world_foundations.dart` utility generates markdown but it is only used as a fallback, not persisted to Supabase.
- **User impact:** Default channels (`info`, `rules`, `roles`) show minimal placeholder text instead of world-specific onboarding content.
- **Proposed fix:** Add `foundation_markdown TEXT` and `foundation_version TEXT NOT NULL DEFAULT 'v1'` columns to `channels` table. Update `Channel` model. Populate `foundationMarkdown` during channel creation using `foundationMarkdownForChannel()`. Backfill existing default channels.
- **Verification:** Every default world has `info`, `rules`, `roles` channels with unique, non-empty markdown content.

---

## P1: Breaks Persistence/Data Trust

### P1-1: Services Return Empty Collections Instead of Surfacing Failures

- **Files:** 20 service files with 58 instances of `return [];` or `return {};`
  - `lib/services/world_service.dart` (8)
  - `lib/services/chat_service.dart` (8)
  - `lib/services/council_service.dart` (6)
  - `lib/services/marketplace_service.dart` (4)
  - `lib/services/rank_service.dart` (4)
  - `lib/services/profile_service.dart` (3)
  - `lib/services/spotlight_service.dart` (3)
  - `lib/services/sanctuary_service.dart` (2)
  - `lib/services/archive_service.dart` (2)
  - `lib/services/moderation_service.dart` (3)
  - `lib/services/ally_service.dart` (2)
  - `lib/services/notification_service.dart` (2)
  - `lib/services/post_service.dart` (2)
  - `lib/services/verification_service.dart` (1)
  - `lib/services/treasury_service.dart` (1)
  - `lib/services/invite_service.dart` (1)
  - `lib/services/announcement_service.dart` (1)
  - `lib/services/poll_service.dart` (1)
  - `lib/services/challenge_service.dart` (1)
  - `lib/services/offline_queue.dart` (1)
  - `lib/services/mutation_outbox_service.dart` (1)
  - `lib/services/league_service.dart` (1)
- **Root cause:** Most are `if (!isSupabaseConfigured()) return [];` guards. While intended as offline fallbacks, they make broken backend wiring indistinguishable from genuinely empty data.
- **User impact:** Features appear to work (empty UI) when the backend is actually broken or unconfigured. Users see blank screens instead of error states.
- **Proposed fix:** Replace silent empty returns with `RepositoryResult`-style returns that distinguish between "no data", "offline", and "error". Surface actionable error states in the UI. Keep empty returns only for truly offline scenarios where cached data should be shown.
- **Verification:** When Supabase is misconfigured, UI shows error state instead of empty list. When offline, cached data is shown with offline indicator.

### P1-2: Offline Queue and Mutation Outbox May Be Duplicated/Competing

- **Files:** `lib/services/offline_queue.dart`, `lib/services/mutation_outbox_service.dart`, `lib/repositories/post_repository.dart`, `lib/repositories/world_repository.dart`
- **Root cause:** Both `offline_queue.dart` and `mutation_outbox_service.dart` exist. `post_repository.dart` uses `MutationOutboxService` via `_runOrQueue()`. `world_repository.dart` also uses `MutationOutboxService`. `offline_queue.dart` uses SharedPreferences for persistence. It is unclear whether they are unified, have separate responsibilities, or compete.
- **User impact:** Mutations may be queued twice, lost, or reconciled incorrectly. Offline behavior is unpredictable.
- **Proposed fix:** Audit both systems. Decide: (a) merge into single outbox with clear temp ID, retry/backoff, reconciliation, and visible failed states, OR (b) define strict separation (e.g., outbox for mutations, queue for sync operations). Remove the unused system.
- **Verification:** A failed mutation while offline appears once in the outbox, retries on reconnect, and shows visible failure state if it cannot be resolved.

### P1-3: Mutations Return Fake Success When Supabase/Auth Missing

- **Files:** `lib/services/post_service.dart`, `lib/services/world_service.dart`, `lib/services/marketplace_service.dart`, `lib/services/treasury_service.dart`, `lib/services/challenge_service.dart`, `lib/services/archive_service.dart`, `lib/services/poll_service.dart`
- **Root cause:** Some mutation methods return `true` or succeed silently when Supabase is not configured or when the actual mutation fails, instead of surfacing the failure.
- **User impact:** Users believe their actions succeeded when data was never persisted. Data loss on app restart.
- **Proposed fix:** Remove fake success returns. Return explicit failure states. Queue mutations in outbox for retry. Show UI error when mutation cannot be completed.
- **Verification:** When Supabase is disconnected, mutations show error or queued state, not success.

### P1-4: SharedPreferences Used for Critical State

- **Files:** `lib/screens/onboarding/the_gate_screen.dart:29,35`, `lib/screens/settings_screen.dart:50,62`, `lib/screens/search_screen.dart:57,75,82`, `lib/widgets/worlds/world_channel_list.dart:34,55`, `lib/state/theme_provider.dart:55,76,82`, `lib/services/storage_service.dart:19-20,49`, `lib/services/offline_queue.dart:42,68,100`
- **Root cause:** SharedPreferences is used for gate completion, theme prefs, search history, channel collapsed state, and offline queue. Gate completion should be tied to resident profile on Supabase, not local storage.
- **User impact:** Gate completion state can be lost or desynced across devices. Theme prefs are fine locally.
- **Proposed fix:** Move gate completion to Supabase resident profile. Keep theme, search history, and channel collapsed state in SharedPreferences (appropriate for local prefs). Ensure offline queue uses durable storage.
- **Verification:** Gate completion survives app reinstall when logged in. Theme prefs persist locally.

### P1-5: Repository Layer Incomplete for Many Domains

- **Files:** `lib/repositories/post_repository.dart`, `lib/repositories/world_repository.dart`, `lib/repositories/profile_repository.dart`, `lib/repositories/notification_repository.dart`
- **Root cause:** Only 4 repositories exist. Many domains (comments, reactions, bookmarks, polls, memberships, notifications, chat, treasury, marketplace, quests, alliances, events, achievements, channel reads) lack repository-level abstraction with durable persistence.
- **User impact:** These features rely directly on services without the offline-first, outbox-backed pattern that repositories provide.
- **Proposed fix:** Create repositories for each domain. Implement cache-first loading, Supabase refresh, realtime updates, and mutation outbox for writes.
- **Verification:** All listed domains have repository wrappers with offline support and durable mutation handling.

---

## P2: Visible UX Quality Issues

### P2-1: GlassPanel/GlassSheet/SovereignCard Used Throughout App

- **Files:** 24 files with GlassPanel (69 usages), 2 files with GlassSheet (4 usages), 3 files with SovereignCard (3 usages)
- **Key locations:**
  - `lib/screens/world_settings_screen.dart` (11 usages)
  - `lib/screens/create_world_screen.dart` (5 usages)
  - `lib/screens/tabs/create_post_screen.dart` (6 usages)
  - `lib/screens/onboarding/the_gate_screen.dart` (1 usage)
  - `lib/screens/world_detail_screen.dart` (4 usages)
  - `lib/screens/league_screen.dart` (3 usages)
  - `lib/screens/subscription_screen.dart` (1 usage)
  - `lib/screens/hall_of_ascension_screen.dart` (2 usages)
  - `lib/screens/verification_review_screen.dart` (2 usages)
  - `lib/screens/audit_log_screen.dart` (1 usage)
  - `lib/screens/world_members_screen.dart` (1 usage)
  - `lib/screens/journey/ascension_path_screen.dart` (1 usage)
  - `lib/widgets/core/sovereign_stat.dart` (1 usage)
  - `lib/widgets/core/screen_loading.dart` (5 usages)
  - `lib/widgets/core/protocol_logs.dart` (1 usage)
  - `lib/widgets/core/loading_state.dart` (1 usage)
  - `lib/widgets/core/sovereign_card.dart` (1 usage)
  - `lib/widgets/core/empty_state.dart` (2 usages)
  - `lib/widgets/chat/chat_input_bar.dart` (1 usage)
  - `lib/widgets/nexus/bento_grid.dart` (1 usage)
  - `lib/widgets/nexus/world_invite_section.dart` (1 usage)
  - `lib/widgets/worlds/*` (multiple)
- **Root cause:** Legacy glassmorphism UI pattern predates Forui integration.
- **User impact:** Heavy glass cards, decorative blur panels, and oversized surfaces conflict with the target compact, clean, social/world app aesthetic.
- **Proposed fix:** Replace with Forui-based wrappers from `lib/ui/**`. Standardize on VCard, VButton, VInput, VBadge, VStates. Preserve glass effects only for generated/share/export visuals.
- **Verification:** `rg "GlassPanel|GlassSheet|SovereignCard" lib` shows only intentional exceptions with comments.

### P2-2: GoogleFonts Overrides in App Surfaces

- **Files:** 14 files with 30 usages
  - `lib/screens/onboarding/the_gate_screen.dart` (10 usages)
  - `lib/screens/subscription_screen.dart` (3 usages)
  - `lib/screens/world_settings_screen.dart` (1 usage)
  - `lib/screens/world_detail_screen.dart` (1 usage)
  - `lib/screens/journey/ascension_path_screen.dart` (2 usages)
  - `lib/widgets/core/daily_reward_dialog.dart` (3 usages)
  - `lib/widgets/core/sovereign_stat.dart` (1 usage)
  - `lib/widgets/worlds/world_info_cards.dart` (1 usage)
  - `lib/widgets/worlds/world_share_card.dart` (2 usages)
  - `lib/widgets/profile/achievement_share_card.dart` (1 usage)
  - `lib/widgets/profile/luminary_nameplate.dart` (2 usages)
  - `lib/widgets/explore/trending_rising_section.dart` (1 usage)
  - `lib/widgets/explore/section_header.dart` (1 usage)
  - `lib/widgets/explore/season_banner.dart` (1 usage)
- **Root cause:** GoogleFonts.manrope and GoogleFonts.spaceGrotesk used for typography overrides instead of Forui/theme typography.
- **User impact:** Inconsistent typography, potential performance impact from font loading, conflicts with theme system.
- **Proposed fix:** Replace with Forui typography tokens. Preserve GoogleFonts only for generated/share/export visuals (share cards, nameplates, achievement cards that are output assets).
- **Verification:** `rg "GoogleFonts" lib` shows only intentional exceptions for output assets.

### P2-3: LinearGradient and BackdropFilter in Ordinary App Surfaces

- **Files:** 22 files with LinearGradient (38 usages), 9 files with BackdropFilter (10 usages)
- **Acceptable uses:** `lib/widgets/worlds/world_banner.dart`, `lib/widgets/worlds/world_share_card.dart`, `lib/widgets/profile/achievement_share_card.dart`, `lib/widgets/profile/cosmetic_avatar.dart`, `lib/widgets/profile/luminary_nameplate.dart`, `lib/widgets/profile/subscription_badge.dart`, `lib/widgets/profile/streak_display.dart`, `lib/widgets/core/notification_bell.dart`, `lib/widgets/core/prestige_up_dialog.dart`, `lib/widgets/core/status_dot.dart`, `lib/screens/splash_screen.dart`, `lib/screens/auth/login_screen.dart`, `lib/screens/auth/auth_callback.dart` (splash, auth backgrounds, share cards, badges, visual effects)
- **Problematic uses:** `lib/screens/world_detail_screen.dart:494,613`, `lib/screens/world_treasury_screen.dart:199`, `lib/screens/onboarding/the_gate_screen.dart:385`, `lib/widgets/core/empty_state.dart:309`, `lib/widgets/explore/boosted_worlds_row.dart:32`, `lib/widgets/journey/progress_trail.dart:92`, `lib/widgets/worlds/world_card.dart:277`, `lib/widgets/worlds/world_hero_banner.dart:119`, `lib/theme/colors.dart:142,147`, `lib/theme/v_colors.dart:91,97,103,109,115`, `lib/widgets/achievements/achievement_card.dart:305`
- **Root cause:** Decorative gradients used in interactive app surfaces where clean, flat surfaces are expected.
- **User impact:** Visual noise, inconsistent with target aesthetic.
- **Proposed fix:** Remove gradients from interactive surfaces. Keep for splash/auth backgrounds, share cards, badges, and visual effects. Replace with solid colors or subtle borders.
- **Verification:** `rg "LinearGradient" lib` shows only intentional exceptions for backgrounds and output assets.

### P2-4: Empty State Widget Uses Glass/Animated/Noisy Design

- **Files:** `lib/widgets/core/empty_state.dart`
- **Root cause:** Empty state implementation uses GlassPanel, BackdropFilter, LinearGradient, and animated art instead of compact icon/title/body/CTA layout.
- **User impact:** Empty states are visually noisy and distract from content.
- **Proposed fix:** Replace with minimal layout: subtle icon, short title, useful body text, optional CTA button. Use Forui tokens for spacing and typography.
- **Verification:** Empty states are compact, clean, and match target design direction.

### P2-5: Theme Files Contain Migration TODOs

- **Files:** `lib/theme/colors.dart`, `lib/theme/design_system.dart`
- **Root cause:** These files contain TODOs to migrate to `VColors`, `VSpacing`, `VRadius`, etc. from `lib/theme/v_colors.dart` and `lib/theme/v_tokens.dart`.
- **User impact:** Inconsistent theming across the app. Some surfaces use old color system, some use new.
- **Proposed fix:** Complete migration. Remove old color definitions. Update all references to use VColors/VTokens. Delete or deprecate `colors.dart` and `design_system.dart` after migration.
- **Verification:** No references to old color constants. All surfaces use VColors/VTokens.

---

## P3: Cleanup/Refactor

### P3-1: Supabase Migration Filename Ordering

- **Files:** `supabase/migrations/20260516_*` (6 files with same date prefix)
  - `20260516_add_subscription_tier.sql`
  - `20260516_phase1_tier_system_overhaul.sql`
  - `20260516_phase4_weekly_leagues.sql`
  - `20260516_security_and_integrity_fixes.sql`
  - `20260516_world_system_complete.sql`
- **Root cause:** Multiple migrations share the same date prefix, making ordering harder to reason about.
- **User impact:** Migration application order may be non-deterministic. Conflicts when applying to fresh vs existing projects.
- **Proposed fix:** Rename with sequential suffixes (e.g., `20260516_001_`, `20260516_002_`, etc.) based on dependency order. Do NOT destructive rewrite -- add new renaming migration if needed.
- **Verification:** Migrations apply in correct order on fresh Supabase project. Existing projects can apply new migrations without reset.

### P3-2: UI Wrappers Under lib/ui/** Should Be Preferred

- **Files:** `lib/ui/buttons/v_button.dart`, `lib/ui/cards/v_card.dart`, `lib/ui/feedback/v_badge.dart`, `lib/ui/feedback/v_states.dart`, `lib/ui/icons/v_icons.dart`, `lib/ui/inputs/v_input.dart`, `lib/ui/media/v_avatar.dart`, `lib/ui/ui.dart`
- **Root cause:** UI wrappers exist but are not consistently used across the app. Many screens still use raw Material/Forui widgets or legacy wrappers.
- **User impact:** Inconsistent styling, duplicated widget code, harder to maintain design system.
- **Proposed fix:** Improve existing wrappers to cover all needed patterns. Replace raw widget usage with V-prefixed wrappers across all screens.
- **Verification:** Most screen UI uses VButton, VCard, VInput, VBadge, VStates, VAvatar, VIcons.

### P3-3: Missing Indexes/Constraints in Supabase Schema

- **Files:** `supabase/migrations/20260515_complete_fresh_schema.sql`, `supabase/migrations/20260518_forui_hybrid_persistence_overhaul.sql`
- **Root cause:** Schema may be missing indexes for common query patterns and constraints for data integrity.
- **User impact:** Slow queries on large datasets. Potential duplicate data (multiple memberships, bookmarks, reactions).
- **Proposed fix:** Add indexes and constraints:
  - One membership per user/world (UNIQUE constraint)
  - One bookmark per user/post (UNIQUE constraint)
  - One reaction per user/post/reaction type (UNIQUE constraint)
  - Index: channel lookup by world/default/name
  - Index: post feed by world/created_at/author
- **Verification:** EXPLAIN ANALYZE shows index usage for feed queries. Duplicate inserts are rejected by constraints.

### P3-4: Missing RPCs for Atomic Operations

- **Files:** `supabase/migrations/`, `lib/services/`
- **Root cause:** Some operations that should be atomic (join world, create post with media, react/unreact, bookmark/unbookmark, comment count updates, poll vote) may be implemented as multiple client-side calls.
- **User impact:** Race conditions, partial failures, inconsistent state.
- **Proposed fix:** Add Supabase RPC functions for atomic operations. Update services to call RPCs instead of multiple client-side queries.
- **Verification:** Atomic operations succeed or fail as a unit. No partial state on failure.

### P3-5: Channel Model Missing foundationMarkdown Field

- **Files:** `lib/models/channel.dart`
- **Root cause:** Channel model has no `foundationMarkdown` or `foundationVersion` fields. Foundation content is generated dynamically by `world_foundations.dart` utility.
- **User impact:** Foundation content cannot be customized per-world in Supabase. All worlds get the same generated content.
- **Proposed fix:** Add `foundationMarkdown` and `foundationVersion` fields to Channel model. Update serialization, Supabase mapping, and channel creation.
- **Verification:** Channel model includes foundation fields. Channel creation populates them. UI loads Supabase content first, falls back to utility.

---

## Audit Summary

| Priority | Count | Status |
|----------|-------|--------|
| P0 | 3 | Pending fix |
| P1 | 5 | Pending fix |
| P2 | 5 | Pending fix |
| P3 | 5 | Pending fix |
| **Total** | **18** | |

## Verification Commands

```bash
# Static analysis
flutter analyze --no-fatal-infos --no-fatal-warnings

# Tests
flutter test

# Legacy widget search (should show only intentional exceptions after fixes)
rg "GlassPanel|GlassSheet|SovereignCard|GoogleFonts" lib

# Gradient search (should show only backgrounds/output assets after fixes)
rg "LinearGradient" lib

# Empty return search (should be reduced after P1 fixes)
rg "return \[\];|return \{\};" lib/services/

# Build verification
flutter build apk --release
```

## Manual Acceptance Checklist

- [ ] New account completes onboarding
- [ ] User lands in starter worlds
- [ ] User can enter first starter world without redirecting back to Nexus
- [ ] Nexus posts load without 42501
- [ ] User creates post, comments, reacts, bookmarks, joins world
- [ ] Restart app -- all actions remain
- [ ] Default channels show world-specific info/rules/roles content
- [ ] App feels compact, white/minimal in light mode
- [ ] App feels AMOLED clean in dark mode
- [ ] No white text on white, black text on black, clipped labels, or oversized card headings
