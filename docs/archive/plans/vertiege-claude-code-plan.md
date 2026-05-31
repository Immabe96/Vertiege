# Vertiege — Claude Code Implementation Plan

> Stack: Flutter + Riverpod + Supabase | Theme: Sovereign Excellence dark
> Use this document as your session guide in Claude Code. Each phase has a context block to paste at the start of every session, followed by specific tasks with suggested prompts.

---

## How to use this plan

1. Start a Claude Code session in your `vertiege/` project root
2. Paste the **Session Context** block at the top of each phase
3. Work through tasks one at a time using the suggested prompts
4. Check off tasks as you go

---

## Phase 1 — Foundation Fixes (Do these first)
*Estimated: 2–3 sessions | No new dependencies needed*

### Session Context (paste this at the start)
```
This is Vertiege, a Flutter + Riverpod + Supabase social app.
Theme: Sovereign Excellence dark (OLED obsidian, sovereign violet, gold tertiary).
Key files:
- lib/theme/colors.dart — AppColors
- lib/theme/design_system.dart — spacing, radius, animation tokens
- lib/models/ — all data models
- lib/services/ — all Supabase service calls
- lib/state/ — all Riverpod providers
- lib/screens/ — all screens
- lib/widgets/ — all reusable widgets
Always match the existing dark theme. Use GlassPanel, GlowBorder, TactileButton, GhostInput from lib/widgets/core/ wherever applicable.
```

### 1.1 — Markdown Rendering in Scrolls
- [ ] **Task:** Add flutter_markdown to pubspec and render message content in WorldChannelScreen and ChatRoomScreen
```
Add flutter_markdown to pubspec.yaml. In lib/screens/world_channel_screen.dart and lib/screens/chat_room_screen.dart, replace plain Text widgets for message content with a MarkdownBody widget. Style it to match AppColors: code blocks use the obsidian surface, links use sovereign violet. Keep it consistent with the existing chat bubble style.
```

### 1.2 — Read/Unread State per Zone
- [ ] **Task:** Track which channels a resident has read and show unread indicators
```
In lib/models/channel.dart, add a lastReadAt timestamp field. Create a Supabase table channel_reads (resident_id, channel_id, last_read_at). Update lib/services/chat_service.dart to mark a channel as read when the resident opens WorldChannelScreen. In lib/widgets/worlds/WorldChannelList, show an unread dot (use the existing StatusDot widget pattern) next to channels with unread messages.
```

### 1.3 — @AllResidents / @Rank Mention Broadcast
- [ ] **Task:** Wire up mention broadcasting so @AllResidents creates notifications
```
In lib/utils/text_parser.dart, the @mention extraction already exists. Extend it to detect @AllResidents and @NearbyResidents (active in last 30 min). When a message is posted in lib/services/chat_service.dart, if it contains @AllResidents, insert a notification row for all world members using notification_service.dart. Use NotificationType from lib/models/notification.dart — add a mention type if not present.
```

### 1.4 — Pinned Notices
- [ ] **Task:** Allow Wardens to pin Scrolls in any Gathering Spot
```
In lib/models/message.dart, add a bool isPinned field. In lib/services/chat_service.dart, add pinMessage(channelId, messageId) and fetchPinnedMessages(channelId) methods using Supabase. In lib/screens/world_channel_screen.dart, add a long-press context menu on messages (for Sovereign/Council ranks only via permission_service.dart) with a Pin option. Add a pinned messages panel at the top of the channel view using GlassPanel widget.
```

---

## Phase 2 — Social Graph (Companions & Bond Requests)
*Estimated: 2 sessions | No new dependencies*

### Session Context (paste this at the start)
```
This is Vertiege, a Flutter + Riverpod + Supabase social app.
I'm implementing the Companions (friends) system. Key existing files:
- lib/models/resident.dart — Resident model
- lib/services/chat_service.dart — DM logic
- lib/screens/chat_list_screen.dart — DM list
- lib/state/resident_provider.dart — resident state
- lib/screens/resident_profile_screen.dart — other resident's profile
- lib/widgets/core/ — GlassPanel, TactileButton, GhostInput etc.
Always match the Sovereign Excellence dark theme.
```

### 2.1 — Companions Data Layer
- [ ] **Task:** Create the friendships table and service
```
Create lib/models/companion.dart with fields: id, requesterId, receiverId, status (pending/accepted/blocked), createdAt. Create lib/services/companion_service.dart with methods: sendBondRequest(residentId), acceptBondRequest(requestId), declineBondRequest(requestId), blockResident(residentId), fetchCompanions(), fetchPendingRequests(). Create the corresponding Supabase table companions with a unique constraint on (requester_id, receiver_id).
```

### 2.2 — Companions Provider
- [ ] **Task:** Wire up Riverpod state
```
Create lib/state/companion_provider.dart using Riverpod. It should expose: companionsProvider (list of accepted companions with their Resident data), pendingRequestsProvider (incoming bond requests), and methods to send/accept/decline/block. Mirror the pattern in lib/state/chat_provider.dart for real-time subscriptions using Supabase channels.
```

### 2.3 — Bond Request UI on Profiles
- [ ] **Task:** Add send/accept/decline buttons to ResidentProfileScreen
```
In lib/screens/resident_profile_screen.dart, add a Bond Request button using TactileButton. Show three states: "Send Bond Request" (no relationship), "Bond Pending" (request sent), "Companions" (accepted). Use companion_provider.dart to drive the state. On the IdentityScreen (/identity), add a Companions tab showing the companions list from companionsProvider, using the existing glass card pattern from ChatListScreen.
```

### 2.4 — Bond Request Notifications
- [ ] **Task:** Notify residents of incoming requests
```
In lib/services/companion_service.dart, when sendBondRequest() is called, insert a row into the notifications table for the receiver using notification_service.dart. Add a new NotificationType.bondRequest in lib/models/notification.dart. In lib/screens/alerts_screen.dart, render bondRequest notifications with Accept/Decline action buttons inline (using TactileButton, small variant).
```

---

## Phase 3 — Channels Overhaul (Districts + Threads)
*Estimated: 3 sessions | No new dependencies*

### Session Context (paste this at the start)
```
This is Vertiege, a Flutter + Riverpod + Supabase social app.
I'm overhauling the channel system to add Districts (categories) and Side Alleys (threads).
Key existing files:
- lib/models/channel.dart — WorldChannel, ChannelType
- lib/services/chat_service.dart + lib/state/channel_provider.dart
- lib/widgets/worlds/WorldChannelList.dart
- lib/screens/world_channel_screen.dart + world_settings_screen.dart
Always match the Sovereign Excellence dark theme.
```

### 3.1 — Districts (Channel Categories)
- [ ] **Task:** Add category grouping to channels
```
In lib/models/channel.dart, add a nullable districtId field and districtName. Create a District model with id, worldId, name, position. Add a districts table in Supabase. Update lib/services/chat_service.dart to fetch channels grouped by district. In lib/widgets/worlds/WorldChannelList, render collapsible district headers (use FadeIn + GlassPanel). In lib/screens/world_settings_screen.dart, add District management (create/rename/delete/reorder) for the Sovereign.
```

### 3.2 — Side Alleys (Threads)
- [ ] **Task:** Add threaded replies to messages
```
In lib/models/message.dart, add threadId (nullable), threadCount (int), isThreadStarter (bool). Create a method in lib/services/chat_service.dart: fetchThreadMessages(threadId) and createThreadReply(parentMessageId, content). Create lib/screens/thread_screen.dart showing the parent message at the top (in a GlassPanel) and thread replies below, with a ChatInputBar at the bottom. In lib/screens/world_channel_screen.dart, add a "Reply in Side Alley" option to the message long-press menu. Show a thread count chip on messages that have replies.
```

### 3.3 — Herald's Board (Announcement Channel)
- [ ] **Task:** Enforce announcement-only posting rules
```
In lib/models/channel.dart, ChannelType.announcement already exists. In lib/services/chat_service.dart, add permission check: only residents with Sovereign or Council standing can post in announcement channels (check via permission_service.dart). In lib/widgets/worlds/WorldChannelList, render announcement channels with a distinct megaphone icon (use world icon map in design_system.dart). In WorldChannelScreen, show a "Read-only for your rank" banner at the bottom for non-moderators using ErrorBanner widget.
```

---

## Phase 4 — Custom Ranks & Edicts (Roles)
*Estimated: 2–3 sessions | No new dependencies*

### Session Context (paste this at the start)
```
This is Vertiege, a Flutter + Riverpod + Supabase social app.
I'm implementing custom Ranks (roles) with Edicts (permissions) per World.
Key existing files:
- lib/services/permission_service.dart — standing-based permissions
- lib/models/resident.dart — WorldStanding
- lib/screens/world_settings_screen.dart — sovereign management panel
- lib/screens/world_members_screen.dart — member roster
Always match the Sovereign Excellence dark theme. Keep the existing tier/standing system intact; custom Ranks are a separate layer on top.
```

### 4.1 — Rank Data Layer
- [ ] **Task:** Create the ranks system in Supabase and Flutter
```
Create lib/models/rank.dart with: id, worldId, name, color (hex), isHoisted, isMentionable, position, edicts (Map<String, bool> of permission flags). Create a world_ranks table in Supabase. Create lib/services/rank_service.dart with: createRank(), updateRank(), deleteRank(), fetchWorldRanks(worldId), assignRank(residentId, rankId), removeRank(residentId, rankId). Create a resident_ranks join table in Supabase.
```

### 4.2 — Rank Management UI
- [ ] **Task:** Build rank editor in WorldSettingsScreen
```
In lib/screens/world_settings_screen.dart, add a Ranks section. Show existing ranks as drag-reorderable tiles (use Flutter's ReorderableListView). Each tile shows a color swatch, rank name, and member count. Add a Create Rank button that opens a GlassSheet bottom sheet with: GhostInput for name, color picker (use a row of color swatches from AppColors tier accents), toggle switches for isHoisted and isMentionable, and a list of Edict toggles (50+ permissions as grouped toggle rows). Use TactileButton for save.
```

### 4.3 — Rank Assignment in Members Screen
- [ ] **Task:** Let the Sovereign assign Ranks to members
```
In lib/screens/world_members_screen.dart, add a long-press or tap action on member rows that opens a GlassSheet showing the member's current Ranks (as colored chips) and a list of all world Ranks to assign/remove. Fetch ranks via rank_service.dart. Show the resident's Ranks as colored chips in their member row (up to 3, then "+N more"). Update lib/screens/resident_profile_screen.dart to also show their Ranks for the current World context.
```

---

## Phase 5 — Voice Campfires (WebRTC)
*Estimated: 4–5 sessions | Requires new dependencies*

### Session Context (paste this at the start)
```
This is Vertiege, a Flutter + Riverpod + Supabase social app.
I'm implementing voice Campfires using LiveKit for WebRTC.
New dependencies to add: livekit_client, permission_handler.
Key existing files:
- lib/models/channel.dart — ChannelType (voice type exists)
- lib/services/chat_service.dart — channel message management
- lib/screens/world_channel_screen.dart
- lib/widgets/core/ — GlassPanel, GlowBorder, TactileButton, StatusDot
LiveKit server URL will be in .env as LIVEKIT_URL. Token generation happens server-side via a Supabase Edge Function.
Always match the Sovereign Excellence dark theme.
```

### 5.1 — Supabase Edge Function for LiveKit Token
- [ ] **Task:** Create server-side token generation
```
Create a Supabase Edge Function at supabase/functions/livekit-token/index.ts. It should accept { roomName, participantIdentity } in the request body, validate the caller is authenticated (check Supabase JWT), then use the LiveKit Server SDK to generate and return a JWT access token. Store LIVEKIT_API_KEY and LIVEKIT_API_SECRET as Supabase secrets.
```

### 5.2 — LiveKit Service in Flutter
- [ ] **Task:** Create the voice service layer
```
Add livekit_client and permission_handler to pubspec.yaml. Create lib/services/voice_service.dart with: joinCampfire(channelId, residentId) — fetches token from the Edge Function then connects to LiveKit room, leaveCampfire(), toggleMute(), toggleDeafen(), fetchCampfireParticipants(channelId). Create lib/state/voice_provider.dart exposing: currentRoomProvider (LiveKit Room?), participantsProvider, isMutedProvider, isDeafenedProvider.
```

### 5.3 — Campfire Participant UI
- [ ] **Task:** Build the voice channel view
```
Create lib/screens/campfire_screen.dart. Layout: top section shows Campfire name and World name. Middle: a grid of participant tiles (each showing CosmeticAvatar, LuminaryNameplate, a speaking indicator — pulsing GlowBorder when audio is active, muted icon overlay when muted). Bottom: a control bar with TactileButton icons for: Mute/Unmute, Deafen/Undeafen, Leave (red). Connect all controls to voice_provider.dart. Use GlassPanel for the overall container.
```

### 5.4 — Campfire Entry in Channel List
- [ ] **Task:** Join voice channels from the channel list
```
In lib/widgets/worlds/WorldChannelList, render voice channels (ChannelType.voice) differently from text channels: show a campfire icon, and below the channel name show small avatar stacks of current participants (fetch from voice_provider). Tapping a voice channel navigates to CampfireScreen instead of WorldChannelScreen. Show a "connected" indicator on voice channels the resident is currently in.
```

### 5.5 — Persistent Voice Status Bar
- [ ] **Task:** Show active voice session while browsing other screens
```
In lib/app.dart or TabLayout, add a persistent mini-bar at the bottom (above the tab bar) that appears when voice_provider has an active room. Show: Campfire name, mute toggle, and a Leave button. This bar persists while the resident navigates to other screens. Use GlassPanel with a subtle violet border. Tapping it navigates back to CampfireScreen.
```

---

## Phase 6 — Push Heralds (Push Notifications)
*Estimated: 1–2 sessions*

### Session Context (paste this at the start)
```
This is Vertiege, a Flutter + Riverpod + Supabase social app.
I'm adding push notifications using Firebase Cloud Messaging (FCM).
Existing: crash_reporter.dart already has Firebase scaffolding.
Key files: lib/services/notification_service.dart, lib/models/notification.dart (9 notification types).
```

### 6.1 — FCM Setup
- [ ] **Task:** Add FCM and request permissions
```
Add firebase_messaging and flutter_local_notifications to pubspec.yaml. In lib/main.dart, after Supabase init, initialize Firebase and FirebaseMessaging. Request notification permission using permission_handler. Get the FCM token and save it to the Supabase profiles table (add a fcm_token column). Create lib/services/push_service.dart handling: foreground messages (show local notification), background messages (via onBackgroundMessage handler), notification tap routing (use app_router.dart to navigate to the right screen based on notification payload).
```

### 6.2 — Server-Side Push Trigger
- [ ] **Task:** Send pushes from Supabase when notifications are created
```
Create a Supabase Database Webhook (or Edge Function triggered on notifications table INSERT). For each new notification row, look up the target resident's fcm_token from profiles, then send a FCM message via the Firebase Admin SDK. Map each NotificationType to an appropriate title/body template (e.g. bondRequest → "New Bond Request from {name}", mention → "{name} mentioned you in {worldName}"). Store FCM_SERVER_KEY as a Supabase secret.
```

---

## Phase 7 — Audit Log & Warden Tools
*Estimated: 1 session*

### Session Context (paste this at the start)
```
This is Vertiege, a Flutter + Riverpod + Supabase social app.
I'm building the Chronicle of Justice (audit log) and bulk message deletion.
Key files: lib/services/moderation_service.dart, lib/screens/world_settings_screen.dart, lib/models/report.dart.
```

### 7.1 — Chronicle of Justice (Audit Log)
- [ ] **Task:** Log all moderation actions and display them
```
Create a world_audit_log table in Supabase with: id, worldId, actorId, targetId (nullable), action (enum: ban, unban, kick, mute, unmute, deleteMessage, editChannel, createRank etc.), details (jsonb), createdAt. In lib/services/moderation_service.dart, insert an audit row after every moderation action. Create lib/screens/audit_log_screen.dart showing a scrollable list of audit entries grouped by date (use ChatDateSeparator widget). Each row shows: actor avatar, action description, target name, timestamp via TimeAgo. Add navigation to it from WorldSettingsScreen, gated to Sovereign/Council only.
```

### 7.2 — Bulk Message Deletion
- [ ] **Task:** Add purge command for Wardens
```
In lib/screens/world_channel_screen.dart, add a long-press selection mode for messages (Warden+ only, checked via permission_service.dart). When in selection mode, show checkboxes on each message and a "Delete Selected" action bar at the top (count of selected + delete button in red using AppColors danger). In lib/services/chat_service.dart, add bulkDeleteMessages(List<String> messageIds) using a Supabase batch delete. Log the bulk delete in audit_log after completion.
```

---

## Phase 8 — OAuth & Security Polish
*Estimated: 1 session*

### Session Context (paste this at the start)
```
This is Vertiege, a Flutter + Riverpod + Supabase social app.
I'm adding OAuth login (Google/Apple) and 2FA (Double Lock).
Key files: lib/services/auth_service.dart, lib/screens/auth/login_screen.dart, lib/screens/settings_screen.dart.
Supabase handles OAuth via its built-in providers.
```

### 8.1 — Google & Apple Sign In
- [ ] **Task:** Add OAuth buttons to LoginScreen
```
Add google_sign_in and sign_in_with_apple to pubspec.yaml. In lib/services/auth_service.dart, add signInWithGoogle() and signInWithApple() methods using Supabase's signInWithOAuth. In lib/screens/auth/login_screen.dart, add "Continue with Google" and "Continue with Apple" TactileButton variants below the existing email form, separated by an "or" divider. Style them to match the dark theme (white text on glass surface, provider logo icon).
```

### 8.2 — Double Lock (TOTP 2FA)
- [ ] **Task:** Add 2FA setup in settings
```
Add otp to pubspec.yaml for TOTP generation/verification. In lib/screens/settings_screen.dart, add a "Double Lock (2FA)" section. When enabling: generate a TOTP secret, display it as a QR code (use qr_flutter package) and as plain text backup. Ask the user to enter a 6-digit code to confirm setup. Store the secret encrypted via secure_storage_service.dart. On subsequent logins in lib/screens/auth/login_screen.dart, after password auth succeeds, check if 2FA is enabled and prompt for the 6-digit TOTP code before completing login.
```

---

## Supabase Tables Checklist

Track which tables you still need to create:

| Table | Phase | Done |
|---|---|---|
| `channel_reads` | 1.2 | [ ] |
| `companions` | 2.1 | [ ] |
| `districts` | 3.1 | [ ] |
| `world_ranks` | 4.1 | [ ] |
| `resident_ranks` | 4.1 | [ ] |
| `world_audit_log` | 7.1 | [ ] |
| `fcm_tokens` (column on profiles) | 6.1 | [ ] |

---

## Flutter Packages to Add (by phase)

| Package | Phase | Purpose |
|---|---|---|
| `flutter_markdown` | 1.1 | Render markdown in messages |
| `livekit_client` | 5 | WebRTC voice/video |
| `permission_handler` | 5 + 6 | Mic, camera, notification permissions |
| `firebase_messaging` | 6 | Push notifications |
| `flutter_local_notifications` | 6 | Foreground notification display |
| `google_sign_in` | 8.1 | Google OAuth |
| `sign_in_with_apple` | 8.2 | Apple OAuth |
| `qr_flutter` | 8.2 | TOTP QR code display |
| `otp` | 8.2 | TOTP generation/verification |

---

## Tips for Claude Code Sessions

- **Always paste the Session Context block first** — it gives Claude Code the file map so it edits the right files
- **One task per message** — don't batch multiple tasks; let Claude Code finish and test each one
- **Reference existing widgets** — remind Claude Code to use `GlassPanel`, `TactileButton`, `GhostInput` etc. so the UI stays consistent
- **After each task, run:** `flutter analyze` to catch type errors before moving on
- **For Supabase schema changes**, ask Claude Code to generate the SQL migration too, not just the Flutter model
- **Voice (Phase 5) is the hardest** — budget extra time and don't skip 5.1 (the Edge Function) before 5.2

---

*Generated for Vertiege — 191 Dart files, Flutter + Riverpod + Supabase*
