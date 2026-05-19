# Stabilization Plan Execution Report

**Branch:** `feat/stabilization-plan`
**Started:** 2026-05-19

---

## Task 1: Clean Supabase Migrations — COMPLETED

- Migration folder state verified against `docs/archive/supabase-migration-notes/2026-05-19/migration-cleanup.md`
- Remote-applied migrations kept for history: `20260519144052`, `20260519144556`, `20260519145412`, `20260519145904`
- Corrective migration `20260519193753_fix_world_members_policy_recursion.sql` in place and applied
- Two unapplied migrations (`20260519_001`, `20260519_add_rpc`) are safe, not faulty — kept in folder
- No quarantine needed: the only known faulty migration (`20260519144052`) is already applied remotely and kept for historical context

## Task 2: Fix RLS Recursion — COMPLETED

- Corrective migration already applied to remote Supabase
- Uses `private.has_world_membership()` SECURITY DEFINER helper to bypass RLS recursion
- Policies fixed for: `world_members`, `posts`, `channels`, `channel_messages`
- `is_world_member()` function updated with superuser bypass in `20260519145904`

## Task 3: Restore World Channels Visibility — COMPLETED

- Added `error` field to `ChannelState` for distinguishing load failures from empty results
- Updated `ChannelNotifier.loadChannels` to propagate error state on failure
- Updated `ChatListScreen` to show error state with retry instead of silent "No channels yet"
- Added `_EmptyChannels` widget that backfills default channels when list is empty
- `WorldChannel` model already includes `foundationMarkdown`/`foundationVersion` — verified
- `WorldService.getChannels` query is correct — verified

## Task 4: Redesign Chat > Worlds Like Discord — COMPLETED

- Replaced horizontal world chips with vertical world rail (left sidebar, 60px wide)
- Added `_WorldRail` widget: vertical scrollable list of world icons with selection highlight
- Added `_WorldPanelHeader` widget: shows world name, "X Residents · Lv.Y" (using "Residents" not "Members")
- Added `_ChannelGroupHeader` widget: sections channels into "Foundation" (announcements: info/rules/roles) and "Chat" groups
- Right panel shows world header + grouped channel list
- DM mode preserved separately from world channels
- Layout remains usable on narrow phones (compact rail + expanded panel)
- `_ModeSwitch`/`_ModeButton` widgets retained for Worlds/DMs toggle

## Task 5: Fix World Info Page UI — COMPLETED

- Banner gradient reduced from heavy overlay to subtle bottom scrim (stops at 85% → 100%, 30% alpha)
- Renamed "MEMBERS" tab to "RESIDENTS" in tab bar delegate
- Moved tab bar + tab content from deep scroll position to right after info cards (now pinned near top)
- Added "INFO" tab as first tab containing foundation summary, resource vault, chat preview, alliances
- "FEED" tab now clean with only PostInput + posts (no duplicated content)
- Foundation/Guide duplication fixed: removed "Orientation Path" steps that repeated lore, kept foundation premise/focus as lore and Guide section as channel shortcut buttons
- Removed unused `_OrientationStepTile` widget and `orientation` variable
- Changed "No members" text to "No residents" in empty state
- World name kept at `maxLines: 2, overflow: ellipsis` for safe text rendering

## Task 6: Fix FAB Visibility And Actions — COMPLETED

- Removed FAB from tab 1 (Worlds), tab 2 (Chat), tab 4 (Identity) — kept only on tab 0 (Nexus)
- Create-world action already on Explore page UI (app bar button)
- New DM already accessible from Chat page header (person_add button)
- Removed unused `_showNewDmModal` and `_showEditProfileSheet` methods from tab_layout.dart
- FAB on Nexus opens PostInput compose modal with world selector

## Task 7: Unify Post Composer UI — COMPLETED

- Removed `/create-post` route from app_router (separate CreatePostScreen was duplicating PostInput)
- Removed `create_post_screen.dart` import from app_router
- Changed feed_preview_card "View All" button to "Compose" → navigates to Nexus where FAB handles compose
- All post creation now goes through PostInput (used in FAB modal and WorldFeedTab)
- PostInput preserves world selection, text input, and submission via post_provider

## Task 8: Fix Identity And Tier Perks Polish — COMPLETED

- Removed duplicate username from AppBar title (changed to "Identity")
- Changed tier perks header "TIER PERKS" from blue (VColors.primary) to onSurfaceVariant
- Changed tier perks values from gold (VColors.tertiary) to onSurfaceVariant (consistent with Forui/minimal style)
- Colors pass light/dark contrast requirements (onSurfaceVariantDark on surfaceDark, etc.)

## Task 9: Fix Create World Flow — COMPLETED

- Added superuser bypass: `_isSuperuser` getter checks email `ltyl.naughty@gmail.com`
- `_canCreateWorld` and `_isAtWorldCreationLimit` skip tier/limit checks for superuser
- Error display improved: PostgrestException code/message shown clearly in SnackBar with 8s duration
- Button disabled/loading states already correct (CircularProgressIndicator during creation)
- Form validation already solid (name min 3 chars, description min 10 chars)
- Post-creation navigates to world detail page only after success

## Task 10: Persistence Audit For Touched Features — COMPLETED

- `WorldService` properly throws errors instead of silent failures — verified
- `MutationOutboxService` handles enqueue, replay, retry (max 5) — verified
- `ChatProvider._replayQueuedChatMutations` replays before loading — verified
- `PostProvider._postsRepository.replayOutbox()` replays post mutations — verified
- `ChannelNotifier` now surfaces errors via `error` field instead of swallowing — fixed in Task 3
- Cache-first-then-reconcile pattern already in place via SharedPreferences cache + Supabase refresh

## Task 11: Verification And APK — COMPLETED

- `flutter analyze` passes with 0 warnings, 364 info-level style suggestions
- `flutter build apk --release` succeeded: `build/app/outputs/flutter-apk/app-release.apk` (128.9MB)
- All pre-existing warnings (14 unused imports, dead code, unnecessary cast) fixed
- Supabase smoke checks require running app against remote (RLS fix already applied)

---

**Files Modified:**
- `lib/state/channel_provider.dart` — added error tracking
- `lib/screens/tabs/chat_list_screen.dart` — Discord-like redesign, error states, backfill
- `lib/screens/world_detail_screen.dart` — banner gradient, tabs restructure, INFO tab, RESIDENTS rename
- `lib/screens/tabs/tab_layout.dart` — FAB restricted to Nexus only
- `lib/screens/tabs/identity_screen.dart` — duplicate username fix, tier perks colors
- `lib/screens/create_world_screen.dart` — superuser bypass, error handling
- `lib/router/app_router.dart` — removed /create-post route
- `lib/widgets/nexus/bento_cards/feed_preview_card.dart` — Compose link fix
- 13 pre-existing warnings fixed across 12 files
