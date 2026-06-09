# Vertiege — Social stack plan (canonical)

**Status:** Active · **Created:** 2026-06-06 · **Waves S1–S5:** delivered on `develop`  
**Supersedes:** All docs in `docs/archive/planning/` (DCX redesign, perfection backlog, wave status, waves 13–22, shadcn migration plan, etc.)

Vertiege’s next engineering focus: make **posts, notifications, presence, and chat** reliable and competitive with modern social/chat apps — without conflating **identity verification** (government ID tick) with **achievement proof** (Nexus standing).

---

## Product shell (unchanged)

| Tab | Job |
|-----|-----|
| **Nexus** | Public standing feed — verified moments, progression |
| **Chat** | Worlds, channels, DMs, Campfire |
| **Identity** | Passport / national ID tick, honour wall, tier |

Borrow **layout patterns** from popular chat apps; use Vertiege lexicon in all UI copy (world, resident, achievement, Campfire — not competitor product names).

---

## Audit summary (2026-06-06)

### Symptoms → root causes

| Symptom | Root cause |
|---------|------------|
| Posts don’t load / feel stale | No disk hydrate on launch; Nexus has **no realtime**; pagination built but **unwired**; 150-post cap; N queries per joined world |
| Message notifications broken / noisy | `addNotification` targets **self**; client INSERTs trigger **real pushes**; foreground **triple delivery** (FCM + local + realtime snack) |
| Online status wrong | `touchPresence()` only updates **local** state; `profiles.last_seen_at` never written; DM header reads once; world “online” uses **fake math**; status picker is **local-only** |

### Chat correctness (high severity)

| ID | Bug |
|----|-----|
| SOC-C01 | Thread replies leak into main channel feed (no `thread_id IS NULL` filter) |
| SOC-C02 | `thread_count` never increments on reply |
| SOC-C03 | DM unread badges always zero (`unread_count` column unused) |
| SOC-C04 | DM `toggleReaction` passes wrong `add` flag — adds fail server sync |
| SOC-C05 | Channel unread false-negative until manual refresh (`loadChannelActivity` not on tab open) |
| SOC-C06 | Realtime listens INSERT only — reactions/edits/pins don’t sync live |

---

## Wave S1 — Stop the bleeding (P0) ✅

**Target:** ~1 week · **Exit:** Cached feed on launch; DM unread works; presence updates; threads stay in threads; no self-push on own reactions.  
**Migrations:** `20260606140000_social_wave_s1.sql`, `20260606150000_social_wave_s1_completion.sql`

### Posts & feed

| ID | Task | Key files |
|----|------|-----------|
| SOC-P01 | Hydrate `@posts_data` on provider init, then background refresh | `post_provider.dart`, `storage_service.dart` |
| SOC-P02 | Wire scroll-end → `loadMorePosts`; stop resetting `_hasMore` on full refresh | `nexus_feed_body.dart`, `post_provider.dart` |
| SOC-P03 | Filter `status = 'published'` in feed RPC/queries | `post_repository.dart`, `list_posts_cursor` migration |
| SOC-P04 | Nexus realtime (multi-world channel or poll fallback) | `post_provider.dart`, `app.dart` |
| SOC-P05 | Unify sort logic (provider vs `nexus_feed_body`) | `post_provider.dart`, `nexus_feed_body.dart` |
| SOC-P06 | Load posts on sign-in (not only bookmarks) | `app.dart` |

### Notifications

| ID | Task | Key files |
|----|------|-----------|
| SOC-N01 | Fix `addNotification` recipient — never default to current user for others’ events | `notification_provider.dart`, `post_provider.dart` |
| SOC-N02 | Server triggers for like/comment → post author; remove client INSERT for social events | Supabase migrations |
| SOC-N03 | Deduplicate foreground delivery (one of: FCM banner / local / in-app snack) | `app.dart`, `push_token_service.dart` |
| SOC-N04 | `PushService.dispose()` + FCM token / `device_tokens` cleanup on sign-out | `notification_provider.dart`, `push_token_service.dart` |
| SOC-N05 | Persist `roomId` in notification cache JSON | `notification_provider.dart` |
| SOC-N06 | Check `notification_preferences` in `send-push` before FCM | `send-push/index.ts` |

### Presence

| ID | Task | Key files |
|----|------|-----------|
| SOC-R01 | `touch_presence` RPC — write `profiles.last_seen_at` on foreground/resume/heartbeat | migration + `resident_provider.dart` |
| SOC-R02 | Refresh/subscribe DM partner presence while room open | `chat_room_screen.dart`, `chat_service.dart` |
| SOC-R03 | Implement or remove `WorldService.residentPresenceCounts` | `world_service.dart`, `world_channel_screen.dart` |
| SOC-R04 | Remove fake online count in world members UI | `world_detail_members.dart` |
| SOC-R05 | Persist `ResidentStatus` to `profiles` or hide picker until wired | `status_picker.dart`, migration |

### Chat

| ID | Task | Key files |
|----|------|-----------|
| SOC-C01 | Filter thread replies from channel fetch + realtime | `chat_service.dart`, `chat_provider.dart` |
| SOC-C02 | `increment_thread_count` trigger/RPC + local parent bump | migration, `chat_provider.dart` |
| SOC-C03 | DM unread from `last_message_at` vs per-user read cursor | migration, `chat_list_screen.dart` |
| SOC-C04 | Fix DM reaction `add` flag | `chat_provider.dart` |
| SOC-C05 | `loadChannelActivity` on Messages tab world load | `chat_list_screen.dart` |
| SOC-C06 | Subscribe UPDATE for reactions/edits/pins/thread_count | `chat_service.dart` |

---

## Wave S2 — Feel alive (P1) ✅

**Target:** ~1 week · **Exit:** New posts appear without manual refresh; notification volume matches settings.  
**Migration:** `20260606160000_social_wave_s2.sql`

| ID | Task |
|----|------|
| SOC-P07 | Single `list_nexus_posts_cursor` RPC (replace N world loops) |
| SOC-P08 | Persist reposts via `create_post` (today local-only) |
| SOC-N07 | Quiet hours enforced server-side in `send-push` |
| SOC-N08 | `ChatNotificationScope` on world channels + thread screens |
| SOC-C07 | Failed-send retry on bubble tap; outbox replay includes reply metadata |
| SOC-C08 | Channel typing indicator UI (already subscribed) |
| SOC-T01 | Tests: `post_provider`, `chat_provider` unread/reaction/thread |

---

## Wave S3 — Social polish (P2) ✅

**Target:** ~2 weeks · Inspired by modern chat app patterns (structure only).  
**Migration:** `20260630170000_social_wave_s3.sql`

### Discord-style patterns → Vertiege

| Pattern | Implementation |
|---------|----------------|
| Per-channel notification overrides | Extend `world_mute_prefs` → mute / mentions-only per channel |
| Unread badges everywhere | DM tab badge, world rail aggregate, Nexus activity |
| Threads first-class | Thread list sheet; unread per thread |
| Rich member list | Real presence + tier ring + resident tick in member sheet |
| @mentions | Push trigger + in-channel highlight |

### Snapchat-style patterns → Vertiege

| Pattern | Implementation |
|---------|----------------|
| Streaks | Honest server streak + Identity UI (notification type exists) |
| Quick media | Channel photo upload (DM has gallery; channel does not) |
| Ephemeral DMs | Expose `auto_delete` prefs in DM room settings |
| Best allies | Allies preview **Message** CTA (today → profile only) |
| Custom status | Persisted status on profile + DM header |
| World activity map | Who’s active in joined worlds (tier/privacy gated) |

### Vertiege moat (do not dilute)

| Feature | Rule |
|---------|------|
| Identity tick | Government ID only — separate from achievement proof |
| Achievement share | Chat ✅ — add moment → Nexus reverse cross-post |
| Tier gates | Visible on locked channels and tools |

| ID | Task | Status |
|----|------|--------|
| SOC-S01 | Read receipts (DMs only) — `message_reads` table | ✅ |
| SOC-S02 | Allies row → open DM (`getOrCreateRoom`) | ✅ |
| SOC-S03 | Channel image attach (parity with DM) | ✅ |
| SOC-S04 | Per-channel mute + mention alerts | ✅ |
| SOC-S05 | Chat → feed cross-post (inverse of existing feed → channel sheet) | ✅ |

---

## Wave S4 — Unread & threads (P2) ✅

**Target:** ~1 week · Remaining S3 pattern table items.

| ID | Task | Status |
|----|------|--------|
| SOC-S06 | Unread badges everywhere — Chat tab, world rail aggregate, Direct mode count | ✅ |
| SOC-S07 | Threads first-class — channel thread list sheet from channel details | ✅ |
| SOC-S08 | Rich member list — presence + tier ring + resident tick in member sheet | ✅ |
| SOC-S09 | Persist custom status to `profiles` + DM header (SOC-R05) | ✅ |
| SOC-S10 | Ephemeral DM `auto_delete` prefs in room settings | ✅ |

---

## Wave S5 — Mentions & activity (P2) ✅

**Target:** ~1 week · Remaining S3 Discord/Snapchat pattern items.

| ID | Task | Status |
|----|------|--------|
| SOC-S11 | @mentions — per-resident push + in-channel highlight + composer autocomplete | ✅ |
| SOC-S12 | Thread unread — per-thread read cursors + badges on thread list/chip | ✅ |
| SOC-S13 | World activity preview — online residents in Messages world panel | ✅ |

---

## Schema / backend (delivered)

| Migration / RPC | Purpose |
|-----------------|---------|
| `20260606140000` / `20260606150000` | Social wave S1 — presence, threads, DM unread, notification fixes |
| `20260606160000` | Social wave S2 — Nexus cursor RPC, reposts, quiet hours |
| `20260630170000` | Social wave S3 — `dm_reads`, `message_reads`, channel mute prefs |
| `20260630180000` | Social wave S4 — `presence_mode`, `custom_status`, `upsert_resident_status()` |
| `20260630190000` | Social wave S5 — per-resident mentions, `channel_id` on notifications, active residents RPC |
| `touch_presence()` / `upsert_resident_status()` | Presence heartbeat + persisted status |
| `list_nexus_posts_cursor` | Single-query Nexus feed |
| `broadcast_channel_mention_notifications` | Per-resident @mention fan-out |
| `send-push` | Preferences + quiet hours (deploy separately from SQL) |

---

## What's next (post S5)

Optional polish from the S3 pattern table — not yet scheduled as a wave:

| Item | Notes |
|------|--------|
| Honest streak UI + server reconcile | `record_daily_check_in` exists; tighten Identity display |
| World activity map (full) | S5 shipped preview avatars in Messages panel |
| @AllResidents / nearby aliases | Broadcast mentions work; expand tests |

---

## Test plan

| Suite | Covers |
|-------|--------|
| `post_provider_test` | Cache hydrate, partial failure, pagination |
| `notification_provider_test` | Recipient ID, no duplicate delivery |
| `chat_unread_test` | DM + channel unread math |
| `chat_provider_reaction_test` | DM add/remove reaction |
| `presence_service_test` | `last_seen` write + idle threshold |

---

## Execution order (historical — S1 bootstrap)

Used for the initial social-stack rescue; waves S1–S6 are complete. For new work, add a **Wave S7** section here before coding.

---

## Wave S6 — chat polish + send-state ✅

**Delivered:** 2026-06-09 · **12 commits on `develop`**

Sequel to S5: cleaned up the chat experience after the social-stack rescue.

| ID | Task | Status |
|----|------|--------|
| S6.A | Chat haptics + DM typing indicator + scroll-to-message on deep link | ✅ |
| S6.B | Fix scroll-to-message offset for dividers; auto-scroll on remote arrival | ✅ |
| S6.C | Float unread chat channels to top of world channel list | ✅ |
| S6.D | Auto-scroll to new-since-visit divider on DM room open | ✅ |
| S6.E | "typing…" label in DM list tile | ✅ |
| S6.F | Thread typing indicator + disable empty send + haptic on reaction tap | ✅ |
| S6.G | Channel tile typing + auto-scroll divider + "New" label on jump FAB | ✅ |
| S6.H | Enable send button with image-only compose (`canSendOverride`) | ✅ |
| S6.I | Achievement share haptic | ✅ |
| S6.J | Read-receipt tooltip with formatted timestamp | ✅ |
| S6.K | Unread dot pulse on 0→N transition in DM list | ✅ |
| S6.L | Report action stub → toast | ✅ |
| S6.M | "Sending…" label on optimistic insert | ✅ |
| S6.N | Pinned banner dismiss + "Pinned" pill chip | ✅ |

### Post-S6 backlog

| Item | Notes |
|------|--------|
| Real Report flow | `reports` table + admin view (S6.L was a toast stub) |
| Honest streak UI + server reconcile | `record_daily_check_in` exists; tighten Identity display |
| World activity map (full) | S5 shipped preview avatars in Messages panel |
| @AllResidents / nearby aliases | Broadcast mentions work; expand tests |
| Voice messages | New feature |
| Search-in-conversation | New feature |
| Quick-reply from push notification | New feature |
| "Last seen X ago" tooltip on profile | Different surface |

---

## Archived planning docs

Historical plans (DCX 144/144, perfection waves 0–6, waves 13–22, shadcn migration, etc.) live in:

**`docs/archive/planning/`**

Do not update archived files for active work — update **this file** (`PLAN.md`) instead.
