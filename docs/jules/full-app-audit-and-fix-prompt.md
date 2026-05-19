# Vertiege Full App Audit + Fix

Run a full product audit and implementation pass across Vertiege's UI/UX, default world content, feature completeness, persistence, and Supabase reliability.

## Non-Negotiables
- Work from branch `main`.
- Keep Supabase as the source of truth for app data and auth.
- Do not deploy to live remote Supabase unless explicitly instructed.
- Make migrations correct, deterministic, complete, and safe for fresh and existing projects.
- If local Supabase cannot run because Docker/linking is unavailable, document that limitation and exact later verification commands.
- Use the real `forui` package and existing app wrappers where present. Do not invent a parallel design system unless a Forui component is genuinely missing.
- Firebase, if present, remains infrastructure-only.
- Android release builds require JDK 21, not system JDK 26.

## First Deliverable
Create `docs/audits/jules-full-app-audit.md` first. Group findings by:
- P0: blocks core app use.
- P1: breaks persistence or data trust.
- P2: visible UX quality issue.
- P3: cleanup/refactor.

Keep this document updated as fixes are completed.

## UI/UX Audit And Forui Cleanup
Audit and fix Nexus/feed, explore/world discovery, world detail, world channels, world settings, profile/identity, onboarding/auth, chat, notifications, achievements, cosmetics, treasury, marketplace, polls, quests, modals, and empty states.

Replace legacy `GlassPanel`, `GlassSheet`, `SovereignCard`, heavy gradients, harsh blur panels, inconsistent Material controls, and GoogleFonts overrides with Forui primitives or thin app wrappers around Forui.

Design rules:
- Light theme: white/minimal surfaces with dark readable text.
- Dark theme: AMOLED black with high-contrast white text.
- Compact mobile layout: 16px page margins, 8-12px gaps, 12-14px body text.
- Accent colors only for semantic status, world identity, rarity, and actions.
- Replace ugly/noisy empty-state imagery, especially no-posts, with minimal Forui-style empty states.
- Remove banner/image gradients that distort artwork. Use only subtle bottom scrims when text overlays images.

Acceptance:
- `rg "GlassPanel|GlassSheet|SovereignCard|GoogleFonts|LinearGradient|BackdropFilter"` should only show intentional exceptions for image viewers/export/share visuals, with comments explaining why.
- No page should show invisible/low-contrast text, clipped labels, or oversized typography in compact app surfaces.

## Default Worlds, Lore, And Starter Channels
Fix default world data so each starter/default world is independent and complete.

Known issues:
- `lib/config/tiers.dart` defines 16 worlds, but no default starter worlds are marked.
- Onboarding hardcodes `neon-district` and `crystal-shore`.
- `lib/utils/world_foundations.dart` has per-world lore, but rules and roles are mostly generic and not persisted into Supabase channel content.
- `WorldService.createDefaultChannels()` creates generic channel descriptions only.

Implement:
- Set `isDefault: true` only for `neon-district` and `crystal-shore` in app config and Supabase seed/backfill.
- Replace hardcoded starter slug checks in onboarding/gate flows with `world.isDefault == true`.
- Add persistent starter content for `info`, `rules`, and `roles`.
- Recommended schema: add `foundation_markdown TEXT` and `foundation_version TEXT NOT NULL DEFAULT 'v1'` to `channels`.
- Update `WorldChannel` and channel UI to load/display `foundationMarkdown` from Supabase first, with `world_foundations.dart` fallback.
- Update `WorldService.createDefaultChannels()` to seed per-world channel descriptions and `foundation_markdown`.
- Backfill existing default channels.

Each of the 16 worlds must have unique lore plus unique `info`, `rules`, and `roles` starter channel text aligned to its domain.

## Supabase Audit And Data Completeness
Inspect and fix migrations, RLS, seed data, and RPCs for real app behavior.

Known issues:
- Several migration files share the same `20260516` version prefix. Rename or squash to unique timestamp prefixes.
- `supabase` is not globally installed; use `npx supabase`.
- Project is not locally linked and Docker may be unavailable.
- Previous `42501` feed/post errors suggest RLS needs verification.
- World seed data is shallow and missing default flags, full lore, channel content, and starter content.

Implement:
- Add/repair policies for feed reads, posts, comments, reactions, bookmarks, world membership, channels, channel reads, polls, marketplace, treasury, notifications, and chat.
- Ensure `world_members` is created on starter onboarding and world join.
- Ensure default channel reads are created on join.
- Add indexes/unique constraints for memberships, bookmarks, reactions, channel lookup, and post feed queries.
- Add RPCs where atomic behavior matters: join world, create post with media, react/unreact, bookmark/unbookmark, comment count updates, poll vote.

Acceptance:
- A fresh Supabase project can run all migrations once.
- Existing project can apply new migrations without destructive resets.
- Authenticated users can read feed, join starter worlds, read default channels, create post/comment/reaction/bookmark, refresh app, and still see data.

## Durable Persistence
Find every feature that appears permanent but stores only locally or loses data on refresh.

Known risks:
- `@alliances_data`, `@quests_data`, `@events_data`.
- Scheduled posts, bookmarks cache, posts cache, achievements cache, notifications cache, recent search, resident cache, and backup restore paths use SharedPreferences.
- Some services return empty/false when Supabase is not configured.
- Offline queue and mutation outbox both exist; verify ownership.

Priority:
1. Fully fix P0/P1 flows: onboarding joins, feed read, posts, comments, reactions, bookmarks, channels, default world data.
2. Implement or scaffold repository/service persistence for alliances, quests, events, polls, marketplace, treasury, chat, notifications, achievements, memberships, and channel reads.
3. Remove fake success behavior where mutations only write local state.

SharedPreferences may only be cache, drafts, preferences, and outbox.

## Tests And Verification
Run after major phases:
- `flutter analyze`
- `flutter test`
- Android release build with JDK 21:
  - PowerShell: set `JAVA_HOME=C:\Users\Immabe\AppData\Local\jdk-21.0.9+10`
  - Then run `flutter build apk --release`

Add or verify tests:
- World config has 16 unique slugs.
- Only `neon-district` and `crystal-shore` are default starter worlds.
- Every world has non-empty lore and unique `info`, `rules`, and `roles` starter text.
- Onboarding joins all default starter worlds and readies default channels.
- Feed read does not produce 42501 for authenticated users.
- Post/comment/reaction/bookmark persists after provider refresh.
- Local cache is not authoritative after Supabase refresh.
- UI smoke/golden checks for Nexus, Discover, World Detail, World Channel, Profile, Composer, Comments, Settings, Auth, and empty states in light/dark themes.

## Manual Acceptance
- New account completes onboarding.
- User lands in starter worlds.
- User can enter first starter world without redirecting back to Nexus.
- Nexus posts load without 42501.
- User creates post, comments, reacts, bookmarks, joins world, restarts app, and all actions remain.
- Default channels show world-specific info/rules/roles content.
- App feels compact, white/minimal in light mode, AMOLED clean in dark mode, with no mismatched gradients or ugly empty images.
