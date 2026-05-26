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
