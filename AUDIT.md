# Vertiege Full Audit — May 2026

## Progress Summary

| Area | Status | Coverage |
|------|--------|----------|
| Screens | 13 built | All planned screens exist |
| Models | 8 models | Resident, Post, World, Channel, Event, Report, Invite, Achievement |
| Providers | 10 Riverpod StateNotifiers | Full CRUD for all entities |
| Services | 10 service classes | Permission, Access, Storage, Auth, Profile, Post, World, Chat, Invite, Backup |
| Widgets | 30+ reusable widgets | Feed, World, Profile, Core, Shared, Achievement |
| Design | Open Design tokens applied | Discord + Duolingo + Supabase |
| Mockups | 2 HTML iPhone 15 Pro frames | Nexus Feed, Identity Profile |
| Analyzer | 0 errors, 0 warnings | Clean |
| Features | 50+ distinct features | Posting, reactions, channels, DMs, mod, events, quests, search |

## Critical Bugs (Fix Immediately)

| # | File | Line | Issue |
|---|------|------|-------|
| 1 | nexus_screen.dart | 121 | `PostInput(worldId: 'neon-district')` — hardcoded world ID, corrupts posts |
| 2 | world_detail_screen.dart | 33-42 | `Future.microtask` in `build()` — triggers auto-join on every rebuild, potential infinite loop |
| 3 | onboarding_screen.dart | 26 | `DateTime.now().millisecondsSinceEpoch.toString()` — collision-prone IDs |
| 4 | resident_profile_screen.dart | 105 | Shows current user's XP on someone else's profile |
| 5 | post_provider.dart | 110 | `addRep(comment.residentId, 3)` — residentId passed as worldId, wrong attribution |
| 6 | channel_provider.dart | 158-167 | `_persist` uses stale read-then-write, data loss on rapid channel creation |
| 7 | chat_provider.dart | 74 | Collision-prone message IDs, silent message drops |
| 8 | app.dart | 30-38 | `_loadStores` has zero error handling — any failure hangs the app on loading spinner |

## Missing States

| Screen | Loading | Empty | Error |
|--------|---------|-------|-------|
| Nexus | ❌ (shows "No posts" instead of spinner) | ✅ | ❌ |
| Identity | ✅ | N/A | ❌ |
| Chat List | ❌ (skeleton only for loading rooms) | ✅ | ❌ |
| Explore | ✅ | ✅ | ❌ |
| World Detail | N/A | ✅ | ❌ |
| Alerts | N/A | ✅ | ❌ |

**Every screen needs error states with retry buttons.**

## Hardcoded Data to Fix

| File | Issue |
|------|-------|
| world_residents.dart:50 | All avatars = `via.placeholder.com` (deprecated, fails) |
| nexus_screen.dart:121 | `worldId: 'neon-district'` |
| reaction_bar.dart | Only 4 emoji, no user-selected highlight |
| settings_screen.dart:63-68 | "Restore Backup" unimplemented |

## Permission Holes (Major Security)

- `addPost()` never calls `WorldPermissions.canPost()` — anyone can post anywhere
- `joinWorld()` never calls `canAccessWorld()` — banned users can rejoin
- Bans/mutes stored locally but not checked on post/comment creation

## Missing Discord-like Features

- No push notifications (FCM not configured)
- No role hierarchy (only sovereign vs everyone)
- No threads/reply chains
- No typing indicators
- No message edit history
- No file attachments beyond images
- No unread counts per channel/DM
- No blocking (only world-level bans)

## Supabase Schema

The app currently uses Supabase for: Posts, Worlds, Channels, Chat Messages, DM Rooms, Invites, Profiles.

If you haven't updated the Supabase SQL schema since the original Phase 1, these tables are missing:
- `events` — world events
- `reports` — post reports  
- `moderation_logs` — ban/mute audit trail
- `quests_progress` — daily quest completion
- `world_members` — member standing/rep per world

## Live Reload Status

✅ App BUILDS successfully on Linux
❌ Runtime crash: ProviderScope `_dirty` assertion during load
🔄 Fix applied: sequential awaits + postFrame callback + loading gate
⏳ Onboarding "Enter the Worlds" button fix in progress
