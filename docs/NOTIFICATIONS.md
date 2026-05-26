# Push notifications (DM + general)

## Flow

1. **DM sent** → `chat_messages` insert → DB trigger `notify_dm_message` creates `notifications` row (`type: dmMessage`, `room_id` set).
2. **Webhook** → `send-push` Edge Function → FCM to `device_tokens`.
3. **Device** → `LocalNotificationService` shows system notification (DM uses data-only FCM + **Reply** action on Android).

## Why DMs were broken

Client tried `NotificationService.createNotification` for the **recipient** while logged in as the **sender**. RLS only allows `recipient_id = auth.uid()`, so inserts failed silently and no push was sent.

## Android inline reply

- Swipe notification → **Reply** → message is sent via `ChatService.sendMessage`.
- Requires an active Supabase session (user signed in).

## Deploy checklist

1. ~~Apply migration `20260527140000_dm_push_notifications.sql`.~~ **Applied** 2026-05-26 (project `wjaphoaxalvgjnrwqjwe`).
2. ~~Redeploy `supabase/functions/send-push`~~ **Deployed** 2026-05-26 (DM data-only + `room_id` route).
3. Install new APK; grant notification permission on Android 13+.
4. Confirm **Settings → Push Notifications** is on.
5. Confirm **Database Webhook** on `public.notifications` INSERT still points at `send-push` with `WEBHOOK_SECRET` bearer auth.
6. **Routing (2026-05-26):** DM pushes use `/chat/{roomId}` (shell). `send-push` `routeFor()` is type-aware.

**iOS:** Custom URL schemes deferred until Mac build host is available.

## Suppress while in chat

`ChatNotificationScope` clears banners for the open DM room only.

## Foreground DM refresh (2026-05-25)

When the app is open and an FCM `dmMessage` arrives, `VertiegeApp` calls `_refreshChatFromForegroundDmPush`:

- `subscribeToDm(roomId)` if not already subscribed
- `loadDmMessages(roomId)` to merge any missed realtime rows
- `loadDmRooms` when the room is missing from the inbox list

## Realtime messaging (client)

| Feature | Implementation |
|---------|----------------|
| Message stream | `chat_messages` Postgres changes per room (`subscribeToDm`) |
| Inbox preview | `dm_rooms` UPDATE subscription + local preview patch on send/receive |
| Typing | Broadcast `typing_{roomId}` + `dm_typing` rows (8s TTL, RPC `upsert_dm_typing`) |
| Pagination | Scroll near top → `loadOlderDmMessages` (100/page, memory cap 300, disk cap 200) |
| Images | Optimistic local path; upload + `sendMessage` in background |
| Reconnect | `ChatConnectionBanner` when Realtime socket drops after first connect |

**Hybrid typing:** live updates use broadcast; `dm_typing` backs on-open hydration and multi-device sync via Postgres Realtime. Rows older than ~8s are ignored on read. Upserts throttled to ~2s per room on the client.

Apply migration `20260528120000_dm_typing_persistence.sql` before shipping the client build.
