# Installed App Stabilization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans or equivalent task-by-task execution. Do not use Jules branches, stale external-agent files, archived plans, or quarantined migrations.

**Goal:** Fix the installed APK issues reported on 2026-05-19: Nexus feed RLS recursion, missing world channels, broken create-world flow, inconsistent world/chat UI, misplaced world tabs, duplicate identity username, incorrect FAB behavior, and inconsistent post composer UI.

**Architecture:** Fix backend access first, then app data loading, then UI. Supabase remains source of truth. Flutter providers/services must surface real backend errors instead of silently showing empty states. UI changes should follow the compact Forui/minimal direction.

**Tech Stack:** Flutter/Dart, Riverpod, go_router, Forui-style app wrappers, Supabase Postgres/RLS, PowerShell, Android build with JDK 21.

---

## Current Verified Facts

- Current branch is `main`.
- Current local app builds successfully as of 2026-05-19.
- Latest APK path: `build/app/outputs/flutter-apk/app-release.apk`.
- Supabase project id: `wjaphoaxalvgjnrwqjwe`.
- Immabe account: `ltyl.naughty@gmail.com`.
- Immabe is a superuser and should have all-world access.
- Remote Supabase currently has 16 worlds and 64 default channels.
- Reported runtime error: `infinite recursion detected in policy for relation "world_members"`, code `42P17`.

---

## Task 1: Clean Supabase Migrations

**Problem:** The migrations folder contains newly generated/high-risk SQL, including a known recursive RLS policy.

**Steps:**

- Compare local migrations with remote migration history before changing migration history again.
- Keep already-applied migrations for history; do not rewrite them after remote application.
- Quarantine unapplied faulty migrations outside `supabase/migrations/`.
- Keep `20260519144052_phase2_rls_policy_fix.sql` as historical context because it was already applied remotely.
- `20260519193753_fix_world_members_policy_recursion.sql` has been applied to remote Supabase as the corrective migration. This timestamped name intentionally replaces the short `20260519_006` request so the fix sorts after the remote-applied 20260519 migrations.
- Maintain `docs/archive/supabase-migration-notes/2026-05-19/migration-cleanup.md` if migration cleanup changes again.

**Acceptance:**

- `supabase/migrations/` contains one coherent migration chain.
- No unapplied faulty migration remains active.
- Fresh projects can run all migrations and end in a working schema.
- Existing remote project can apply the corrective migration without reset.

---

## Task 2: Fix Supabase World Membership RLS Recursion

**Problem:** `20260519144052_phase2_rls_policy_fix.sql` introduced a `world_members` SELECT policy that queries `world_members` inside a `world_members` policy, causing `42P17`.

**Files:**

- Already applied: `supabase/migrations/20260519193753_fix_world_members_policy_recursion.sql`
- Inspect: existing `supabase/migrations/*.sql`

**Steps:**

- Drop the recursive policy named `"Members can read world members"` if it exists.
- Replace any `world_members` policy that calls `is_world_member(world_id)` or queries `world_members` directly from a `world_members` policy.
- Use the non-recursive `private.has_world_membership(world_id, resident_id)` helper with fixed `search_path`.
- Use the helper in policies for `posts`, `channels`, `channel_messages`, and `world_members`.
- Keep `public.is_superuser()` bypass in relevant policies.
- Do not narrow existing public/member read behavior unless a test proves it is unsafe.

**Acceptance:**

- Nexus feed no longer throws `42P17`.
- Immabe can read all posts, worlds, residents, and channels.
- A normal authenticated user can read joined-world posts and channels.
- A non-member cannot read private member-only data.

---

## Task 3: Restore World Channels Visibility

**Problem:** Channels do not appear in any world.

**Files:**

- Modify: `lib/services/world_service.dart`
- Modify: `lib/state/chat_provider.dart`
- Modify: `lib/screens/world_channel_screen.dart`
- Modify: `lib/screens/tabs/chat_list_screen.dart`

**Steps:**

- After RLS fix, verify whether channels load from Supabase.
- If queries still fail, fix `WorldService.getChannels` to use current schema and RLS-compatible filters.
- Ensure channel models include and display `foundationMarkdown` and `foundationVersion` when available.
- Show a real error state if loading fails; do not display "no channels" when the backend returned an error.
- Ensure joined worlds always show `info`, `rules`, `roles`, and `general`.

**Acceptance:**

- Every default world shows channels.
- Channel content persists after app restart.
- Missing channels are repaired by service/backfill, not hidden.

---

## Task 4: Redesign Chat > Worlds Like Discord

**Problem:** Worlds page currently uses horizontal chips and does not match the requested Discord-like world/channel interface.

**Files:**

- Modify: `lib/screens/tabs/chat_list_screen.dart`

**Steps:**

- Replace horizontal world chips with a compact two-panel mobile layout:
  - left rail: vertical world icons/images,
  - right panel: selected world header, active/resident count, and channel list.
- Selecting a world reloads its channels.
- Show channels grouped by `info`, `rules`, `roles`, and chat/general channels.
- Use "Residents" wording, not "Members".
- Keep DMs separate from world channels.

**Acceptance:**

- User can switch worlds from the left rail.
- Selected world channels appear immediately.
- Active/resident details are visible.
- Layout remains usable on narrow phones.

---

## Task 5: Fix World Info Page UI

**Problems:**

- Banner image gradient distorts artwork.
- Header text spills over and becomes invisible.
- `World Foundation` and `World Guide` repeat the same content.
- Tab menu appears too low.
- `Members` should be `Residents`.

**Files:**

- Modify: `lib/screens/world_detail_screen.dart`

**Steps:**

- Remove heavy banner gradient.
- Keep only a subtle bottom scrim if text overlays an image.
- Move tabs to the top/pinned area below the app bar or top header.
- Rename `Members` tab to `Residents`.
- Make foundation content show lore/identity.
- Make guide content show channel/action shortcuts, not duplicate lore.
- Fix title/header constraints so text never spills into invisible areas.

**Acceptance:**

- Banner image looks natural.
- No text overlaps or disappears.
- Tabs are visible near the top.
- Duplicate foundation/guide copy is removed.

---

## Task 6: Fix FAB Visibility And Actions

**Problems:**

- FAB appears on pages where it should not.
- FAB exposes wrong actions.
- FAB post composer uses a different/basic UI.

**Files:**

- Modify: `lib/screens/tabs/tab_layout.dart`
- Inspect: `lib/router/app_router.dart`
- Inspect composer widgets under `lib/widgets/feed/`

**Steps:**

- Make FAB route-aware, not only tab-index-aware.
- Show compose FAB only on Nexus/feed where it makes sense.
- Hide FAB on Chat, Identity, Shop, world detail, settings, create-world, and modal flows.
- Move create-world action to explicit page UI, not global FAB.
- Route all post creation entry points to one modern composer.

**Acceptance:**

- FAB appears only on allowed feed surfaces.
- FAB never opens unrelated actions.
- Nexus and FAB composer UI are the same.

---

## Task 7: Unify Post Composer UI

**Problem:** Nexus latest posts uses modern UI, but FAB opens a basic composer.

**Steps:**

- Choose one canonical modern composer.
- Replace older/basic composer entry points with the canonical composer.
- Preserve world selection, media, text, and submit behavior.
- Ensure post creation persists through Supabase/outbox and refresh.

**Acceptance:**

- All create-post paths look and behave consistently.
- Created posts persist after refresh/restart.

---

## Task 8: Fix Identity And Tier Perks Polish

**Problems:**

- Identity username appears twice.
- Tier perks text is blue and clashes with Forui/minimal style.

**Files:**

- Modify: `lib/screens/tabs/identity_screen.dart`

**Steps:**

- Remove the upper-left username display.
- Keep the primary username under the profile image.
- Change tier perks text to theme `onSurface` / `onSurfaceVariant`.
- Use accent color only for semantic highlights or selected states.
- Check light and AMOLED dark contrast.

**Acceptance:**

- Username appears once.
- Tier perks fit the Forui/minimal theme.
- No low-contrast text.

---

## Task 9: Fix Create World Flow

**Problem:** Create button does nothing and an error appears after form completion.

**Files:**

- Modify: `lib/screens/create_world_screen.dart`
- Modify: `lib/services/world_service.dart`
- Modify: relevant world provider/state file.

**Steps:**

- Capture and display the exact Supabase/service error.
- Ensure button disabled/loading states are correct.
- Ensure form validation blocks bad data before submit.
- Ensure world insert, creator membership insert, and default channel creation all succeed.
- Ensure Immabe/superuser bypasses normal tier/limit restrictions.
- Refresh world/member/channel providers after success.
- Navigate only after the new world exists locally and remotely.

**Acceptance:**

- Immabe can create a world.
- New world appears in Explore and Chat > Worlds.
- New world has default channels.
- New world persists after restart.

---

## Task 10: Persistence Audit For Touched Features

**Problem:** Several actions may still appear successful but rely on local cache or fail silently.

**Steps:**

- Remove fake-success behavior in touched flows.
- SharedPreferences may be cache/drafts/outbox only, not authoritative state.
- On refresh, load cache first only as a temporary display, then reconcile with Supabase.
- Failed offline/outbox mutations must be visible and retryable.

**Acceptance:**

- Posts, channels, chat messages, world joins, and created worlds persist after restart.
- Backend failures show actionable UI.

---

## Task 11: Verification And APK

**Commands:**

```powershell
$env:JAVA_HOME="C:\Users\Immabe\AppData\Local\jdk-21.0.9+10"
flutter pub get
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test
flutter build apk --release
```

**Supabase smoke checks:**

- Authenticated user can read Nexus feed.
- Authenticated user can read joined-world channels.
- Immabe can read all worlds/channels/residents.
- Create world creates world, membership, and default channels.
- Channel messages persist.
- Denied private rows remain denied.

**Manual APK checks:**

- Nexus posts load without `42P17`.
- Channels show in every world.
- Chat > Worlds works like Discord world/channel navigation.
- Identity username is not duplicated.
- Tier perks are not blue.
- World detail banner/tabs/content are fixed.
- FAB appears only where appropriate.
- Post composer UI is consistent.
- Create world works and persists.

---

## Best Practices For The Implementing Agent

- Work in small commits by task.
- Fix backend/RLS before UI; otherwise UI debugging will be misleading.
- Do not trust archived Jules/OpenCode plans.
- Do not use broad regex rewrites.
- Do not silently swallow Supabase errors.
- Preserve existing routes and features unless this plan explicitly changes them.
- Prefer existing app UI wrappers and Forui-style theme tokens.
- Keep images natural; avoid heavy gradients/glass unless needed for readable text overlays.
- Build APK only after major fixes, not after every tiny change.
