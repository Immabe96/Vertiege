# RLS & Migration Audit

**Date:** 2026-05-19 · **Updated:** 2026-05-21  
**Phase:** 6 — Supabase Reliability

---

## Migration Status (2026-05-21)

**Remote:** 32 versions applied — full manifest in [2026-05-21-migration-reconciliation.md](./2026-05-21-migration-reconciliation.md).

**Local `supabase/migrations/`:** 12 files aligned with remote tail (`20260519144052` … `20260520150000`).

**Archived:** Fresh-project-only SQL in `supabase/migrations_archive/fresh_project_only/` — do not apply to `wjaphoaxalvgjnrwqjwe`.

| Migration | Status | Notes |
|-----------|--------|-------|
| `20260519144052` … `20260519193753` | Applied | RLS fixes, channels, chat, superuser |
| `20260520080241` | Applied | Firebase storage + notifications |
| `20260520115334` | Applied | Webhook secret to Vault |
| `20260520121347` | Applied | `device_tokens` own-row RLS |
| `20260520130000` | Applied | Security corrective (anon revoke, search_path) |
| `20260520140000` | Applied | `create_world_full` RPC |
| `20260520150000` | Applied | Daily rewards / events tables |

---

## RLS Policies — Current State

### Fixed (stabilization report confirmed)
- `world_members` — SECURITY DEFINER `private.has_world_membership()` helper
- `posts` — no recursive policy
- `channels` — no recursive policy
- `channel_messages` — no recursive policy

### Verified on remote (2026-05-21)
- `device_tokens` — own-row policies via `20260520121347`
- `world_members`, `posts`, `channels`, `channel_messages` — recursion fix `20260519193753`

### Requires Verification (spot-check in SQL editor)
- `worlds` — SELECT/INSERT/UPDATE/DELETE policies
- `profiles` — SELECT/UPDATE policies
- `comments` — SELECT/INSERT/DELETE policies
- `reactions` — SELECT/INSERT/DELETE policies
- `bookmarks` — SELECT/INSERT/DELETE policies
- `polls` / `poll_votes` — SELECT/INSERT policies
- `quests` / `quest_progress` — SELECT/INSERT/UPDATE policies
- `events` / `event_rsvps` — SELECT/INSERT policies
- `notifications` — SELECT/INSERT/UPDATE policies
- `marketplace` / `marketplace_transactions` — SELECT/INSERT policies
- `treasury` / `treasury_transactions` — SELECT/INSERT policies
- `achievements` / `user_achievements` — SELECT/INSERT policies
- `device_tokens` — SELECT/INSERT/DELETE policies
- `storage.objects` — bucket-level policies

---

## RPC Verification

### Existing
- `private.has_world_membership(resident_id, world_id)` — SECURITY DEFINER, fixed search_path — VERIFIED

### Recommended additions (future phases)
- `create_world(name, slug, type, ...)` — transactional world creation
- `join_world(world_id, resident_id)` — membership + starter channels
- `create_post(world_id, author_id, content)` — post with moderation
- `add_comment(post_id, author_id, content)` — comment with moderation
- `add_reaction(post_id, user_id, emoji)` — upsert reaction
- `toggle_bookmark(post_id, user_id)` — bookmark/unbookmark
- `vote_poll(poll_id, option_id, user_id)` — poll vote with uniqueness
- `update_quest_progress(quest_id, user_id, progress)` — quest tracking
- `rsvp_event(event_id, user_id, status)` — event RSVP
- `get_unread_notifications(user_id)` — batched notification query

---

## Index Recommendations

### Missing indexes (based on common query patterns)
- `posts(world_id, created_at DESC)` — feed queries
- `comments(post_id, created_at)` — comment threads
- `reactions(post_id, user_id)` — reaction lookups
- `bookmarks(user_id, post_id)` — bookmark queries
- `channel_messages(channel_id, created_at DESC)` — channel message pagination
- `notifications(user_id, read, created_at DESC)` — unread notifications
- `world_members(resident_id)` — resident's joined worlds
- `dm_messages(room_id, created_at DESC)` — DM pagination
- `marketplace_listings(world_id, category)` — marketplace filters

### Existing indexes
- Primary keys on all tables
- Foreign key indexes (implicit via REFERENCES)

---

## Recursive Policy Check

- Searched all migrations for `EXISTS (SELECT ... FROM` patterns within policies
- The only recursive pattern was in `world_members` → `posts` → `world_members`, fixed by `20260519193753`
- All other policies use direct column comparisons or `auth.uid()` checks
- **Verdict: No remaining recursive policy patterns**

---

## Superuser Access

- `is_world_member()` function has superuser bypass for `ltyl.naughty@gmail.com`
- Immabe can access all worlds regardless of tier or visibility
- **Verdict: Correctly configured**

---

## Outstanding Actions

- [x] Reconcile migration files with remote — see [migration-reconciliation](./2026-05-21-migration-reconciliation.md)
- [ ] Verify RLS on tables listed in "Requires Verification"
- [x] Apply `20260521120000_security_followup` on remote (2026-05-21)
- [ ] Add recommended indexes for feed, comments, reactions, notifications, and marketplace
- [ ] Create transactional RPCs for core mutations
- [ ] Audit storage bucket policies for avatars, world banners, post media, and verification evidence
