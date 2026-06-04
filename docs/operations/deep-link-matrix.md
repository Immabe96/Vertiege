# Deep link matrix

Reference for cold-start routing, push taps, and custom URL schemes.  
**Scheme:** `vertiege://` · **HTTPS:** not configured in v1 (app links TBD).

---

## Custom scheme hosts (`vertiege://`)

| Host / pattern | Redirect | In-app route | Auth required |
|----------------|----------|--------------|---------------|
| `invite/{code}` | [deep_link_redirects.dart](../../lib/router/deep_link_redirects.dart) | `/invite/{code}` → accept → world or home | After signup for accept |
| `auth/callback` | → `/auth/callback` | OAuth / magic link completion | — |
| `verifier/login` | → `/verifier/login` | Staff verifier login | Verifier role |

---

## App routes (GoRouter)

| Path | Purpose | Cold start | Push / notification |
|------|---------|------------|---------------------|
| `/` | Nexus tab | Yes | — |
| `/explore` | Worlds tab | Yes | `welcome` → here |
| `/explore/discover` | World discovery list | Yes | — |
| `/explore/:worldId` | World home | Yes | `mention`, `worldUnlocked`, like/comment with world |
| `/explore/:worldId?post=` | World feed + post highlight | Yes | `like`, `comment`, `reactionMilestone` |
| `/explore/:worldId/:channel` | Text channel | Yes | — |
| `/campfire/:channelId?worldId=&worldName=&name=` | Voice Campfire | Yes | — |
| `/thread/:messageId` | Thread (needs extra or loader) | Partial | — |
| `/post/:postId` | Post deep link loader | Yes | Legacy FCM |
| `/notifications/:id` | Notification row loader | Yes | FCM `notification_id` |
| `/invite/:code` | Invite accept screen | Yes | Share links |
| `/chat` | Chat tab | Yes | `dmMessage` (no room) |
| `/chat/:roomId` | DM room | Yes | `dmMessage` with `roomId` |
| `/residents/:id` | Public profile | Yes | — |
| `/achievements` | Achievement hub | Yes | `achievementApproved` / `rejected` |
| `/allies` | Allegiances | Yes | `allegianceRequest` |
| `/identity` | Identity tab | Yes | `tierUpgrade`, `streakReminder` |
| `/season` | Season meta | Yes | `ranking` |
| `/settings` | Settings | Yes | `modAction` |
| `/auth/callback` | Supabase auth | Yes | — |
| `/verifier/login`, `/verifier/review` | Verifier portal | Yes | — |

Resolver for notification rows: [notification_navigation.dart](../../lib/router/notification_navigation.dart).

---

## Notification type → route

| `NotificationType` | Route when data present |
|--------------------|-------------------------|
| `achievementApproved`, `achievementRejected` | `/achievements` |
| `allegianceRequest` | `/allies` |
| `like`, `comment` | `exploreWorldPath(worldId, postId: postId)` or `/notifications` |
| `dmMessage` | `chatShellPath(roomId)` or `/chat` |
| `mention`, `worldUnlocked` | `exploreWorldPath(worldId)` or `/notifications` |
| `tierUpgrade`, `streakReminder` | `/identity` |
| `welcome` | `/explore` |
| `modAction` | `/settings` |
| `ranking` | `/season` |
| `reactionMilestone` | World + post or `/identity` |

Tests: [notification_navigation_test.dart](../../test/router/notification_navigation_test.dart).

---

## Manual smoke (API 30+)

1. Kill app → open `vertiege://invite/TEST` (valid code) → sign in → lands on world, not invite loop.  
2. Tap push for DM → opens `/chat/{roomId}`.  
3. Tap push for like → opens world feed with post visible.  
4. Open world → voice channel → Campfire URL has `worldId` query param.

Wave 6 full checklist: [wave-6-signoff-checklist.md](uat/wave-6-signoff-checklist.md) (**deferred** — run on device when ready).
