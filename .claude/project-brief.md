# Vertiege — AI Project Brief

**Purpose:** Single-file context for any AI to plan a UI/UX overhaul. Read this + `PROGRESS.md` for full picture.

## 1. What Vertiege Is

A semi-social, semi-gamified Flutter mobile app. Residents (users) distinguished by real-world achievements, earn prestige, and level up. A **Realm** contains many **Worlds** (gated communities). Each world has Discord-style channels + Twitter-style feed. All posts from joined worlds aggregate into the **Realm Feed** (Nexus).

Three world types:
- **Wealth** — paid access ($4.99–$49.99), 5 tiers
- **Profession** — proof-based (upload certificate → manual review)
- **Dominion** — user-created, level up via activity + paid boosts

Governance: 1 Sovereign + 10 Council members per dominion world. 15-day inactivity ejection. Sovereign elected by council vote (random tiebreaker).

## 2. Tech Stack

| Layer | Choice |
|-------|--------|
| Framework | Flutter 3.x, Dart 3.11+ |
| State | Riverpod (10 StateNotifierProviders) |
| Navigation | go_router (StatefulShellRoute, 5 tabs) |
| Backend | Supabase (Postgres + Storage + Realtime) |
| Auth | Supabase Auth (email + OTP) |
| IAP | in_app_purchase (gated behind `StoreService.isEnabled = false`) |
| Storage | SharedPreferences + FlutterSecureStorage |
| Fonts | Google Fonts (loaded at startup) |
| Images | image_picker (camera/gallery), cached_network_image |

## 3. Navigation — 23 Routes, 5 Tabs

```
/login                    → LoginScreen
/signup                   → SignUpScreen
/onboarding               → OnboardingScreen
/auth/callback            → AuthCallbackScreen (deep-link, placeholder)
/settings                 → SettingsScreen
/search                   → SearchScreen
/create-world             → CreateWorldScreen
/residents/:id            → ResidentProfileScreen
/achievements             → AchievementsIndexScreen
/achievements/:category   → AchievementCategoryScreen
/achievements/submit      → SubmitAchievementScreen
/admin/verifications      → VerificationReviewScreen
/invite/:code             → AcceptInviteScreen (inline widget)

═══ Tab 1: Feed ═══
/                         → NexusScreen (Realm Feed)

═══ Tab 2: Explore ═══
/explore                  → ExploreScreen (world list)
/explore/:worldId         → WorldDetailScreen
/explore/:worldId/:channelName → WorldChannelScreen
/explore/:worldId/settings → WorldSettingsScreen
/explore/:worldId/members → WorldMembersScreen

═══ Tab 3: Chat ═══
/chat                     → ChatListScreen
/chat/:roomId             → ChatRoomScreen

═══ Tab 4: Profile ═══
/identity                 → IdentityScreen

═══ Tab 5: Alerts ═══
/alerts                   → AlertsScreen
```

**Auth guard:** Global `redirect` in router — no session → `/login`, no profile → `/onboarding`, authed → skip auth pages.

**Tab scaffold:** `TabLayout` widget wraps `StatefulShellRoute` with a bottom NavigationBar.

## 4. State Management — 10 Providers

| Provider | State Class | What it holds |
|----------|------------|---------------|
| `worldProvider` | `WorldState` | `Map<String, World>` — all worlds (15 hardcoded + user-created) |
| `residentProvider` | `ResidentState` | Current `Resident`, loading flag, verification status |
| `postProvider` | `PostState` | `List<Post>`, bookmarked IDs, error string |
| `channelProvider` | `ChannelState` | `Map<String, List<Channel>>` by world ID |
| `chatProvider` | `ChatState` | DM rooms, DM messages, channel messages |
| `eventProvider` | `EventState` | `Map<String, List<Event>>` by world ID |
| `achievementProvider` | `AchievementState` | Achievements, total XP, recently-unlocked, celebration tier |
| `questProvider` | `QuestState` | Daily quests, date key |
| `notificationProvider` | `NotificationState` | `List<Notification>`, loading flag |
| `themeProvider` | `ThemeState` | `ThemeScheme` enum (system/light/dark) |

## 5. Services — 18 Files

| Service | Role |
|---------|------|
| `AuthService` | Supabase email/OAuth sign-in, sign-up, OTP, session stream |
| `ProfileService` | Upsert/fetch/search resident profiles in Supabase |
| `WorldService` | CRUD worlds, memberships, channels via Supabase |
| `PostService` | Sync posts, reactions, comments to Supabase |
| `ChatService` | DM rooms, DM messages, channel messages, Supabase Realtime |
| `NotificationService` | Fetch, mark-read, create notifications |
| `InviteService` | 6-char invite codes, validate/accept, list per world |
| `CouncilService` | 15-day inactivity ejection, sovereign election, seat backfill |
| `PrestigeService` | Calculate world prestige from activity metrics, persist |
| `VerificationService` | Upload proof to Supabase Storage, approve/reject submissions |
| `ModerationService` | Mute/ban logging, report submission, moderation logs |
| `PermissionService` | `WorldPermissions` — canPost, canComment, canModerate, etc. |
| `AccessControl` | Top-level `canAccessWorld()` — tier/profession/wealth gates |
| `StoreService` | IAP wrapper — buyWealthTier, buyWorldBoost, restore (gated) |
| `StorageService` | SharedPreferences with debounced write, named keys |
| `SecureStorageService` | FlutterSecureStorage for auth tokens |
| `BackupService` | Serialize/restore all local data as JSON |
| `supabase.dart` | `getSupabase()` helper, `isSupabaseConfigured()` check |

## 6. Data Models (lib/models/)

| Model | Key Fields |
|-------|-----------|
| `Resident` | id, name, tier (1-5), profession, verifiedRoles, avatarUrl, bio, decorations, badges, joinedWorldIds, wealthWorldsUnlocked, worldStandings, bannedWorldIds, mutedUntil |
| `World` (extends WorldBase) | id, name, type (enum), description, sovereignId/Name, prestige, memberCount, icon, activityScore, requiredTier, requiredProfession, constitution, boostCount, lastBoostMonth |
| `WorldBase` | Shared fields between World and DominionWorld |
| `DominionWorld` | Extends WorldBase, adds constitution + memberIds |
| `WorldConstitution` | admission, minTier, requiredProfession, posting rule, commenting rule, contentTypes, entryFee |
| `WorldFeatures` | boolean gates: lounge, events, vault, audioRooms, marketplace, treasury, alliances, landmarks, governance |
| `Post` | id, authorId/Name, content, media, reactions, comments, timestamp, worldId, repost metadata, pinned |
| `Channel` | id, worldId, name, description, type (feed/announcement/lounge/chat) |
| `Event` | id, worldId, title, description, startsAt, rsvpIds, createdBy |
| `Achievement` | id, category, title, description, xp, icon, criteria |
| `WorldInvite` | code, worldId, createdBy, uses, maxUses, expiresAt |
| `ResidentTier` | enum: hustlers(1), highRollers(2), elite(3), oldMoney(4), apex(5) |
| `WorldType` | enum: wealth, profession, dominion |
| `VerificationStatus` | enum: idle, verifying, success, failed |

## 7. Widget Inventory — 38 Public Widgets in 6 Groups

### core/ (15 widgets)
`AppEmptyState`, `AppErrorState`, `FadeIn` (staggered entrance), `ImageViewer` (full-screen zoom), `NotificationBell` (badge + pulse), `OfflineBanner`, `SafeScreen`, `ScreenHeader`, `Shimmer`/`ShimmerPostCard`/`ShimmerChatTile` (loading), `Skeleton` (deprecated), `StatusDot` (Discord-style presence), `AnimatedProgressBar`, `TactileButton` (Duolingo 3D press), `ThemedText` (typed text styles)

### feed/ (6 widgets)
`PostItem` (full feed card: avatar, tier, content, reactions, comments), `PostInput` (composer with image attach), `CommentSheet` (bottom sheet), `MediaGrid`, `PostImage`, `ReactionBar` (emoji row + haptics)

### worlds/ (8 widgets)
`WorldCard` (explore list card), `WorldBanner` (cover image), `WorldAccessGuard` (tier gate + purchase/verify flow), `WorldChannelList`, `WorldResidents` (avatar grid), `WorldLeaderboard` (top 10 by rep), `AccessIcon` (lock/unlock), `AccessGuard` (deprecated overlay)

### profile/ (5 widgets)
`CosmeticAvatar` (tier-bordered circle, handles FileImage/NetworkImage/AssetImage), `NameBanner`, `Badge`, `BadgeDisplay` (horizontal scroll), `ShareCard` (generates shareable stat card)

### achievements/ (3 widgets)
`AchievementCard`, `AchievementGrid` (filterable), `TierCelebration` (confetti + perks on level-up)

### shared/ (6 widgets)
`HapticTab`, `ImagePickerWidget`, `ParallaxScroll`, `AppProgressBar`, `AppSearchBar`, `TierIcon`

## 8. Theme & Design System

Defined in `lib/theme/`:
- **`design_system.dart`** — Tokens: `Spacing` (xs/sm/md/lg/xl/xxl), `RadiusTokens` (sm/md/lg/round), `IconSizes`, `FontSizes`, `LetterSpacing`, `LineHeight`, `AnimDurations`, `AnimCurves`
- **`colors.dart`** — `AppColors`: brandGreen, gold, streakOrange, online, alphaBorder, purple, etc.
- **`theme_factory.dart`** — Light/dark `ThemeData` build via `ThemeFactory`
- **Theme mode:** System/Light/Dark, persisted in SharedPreferences

Current UI style: Dark-first, card-based, gradient banners, Material 3. Google Fonts loaded at startup (specific font family names vary by screen).

## 9. Supabase Schema — 13 Tables

`profiles`, `worlds`, `world_members`, `channels`, `posts`, `events`, `reports`, `invites`, `dm_rooms`, `chat_messages`, `channel_messages`, `notifications`, `moderation_logs`

Supabase URL: `https://wjaphoaxalvgjnrwqjwe.supabase.co` (key in gitignored `.env`)

## 10. Known Issues & Pain Points

- Several screens use `NetworkImage` directly instead of `CosmeticAvatar` — breaks with local file paths
- No push notification setup (in-app only via Supabase Realtime)
- `AuthCallbackScreen` is a placeholder (no deep-link handling)
- `Skeleton` widget is deprecated but still present alongside `Shimmer`
- `AccessGuard` widget is deprecated (replaced by `WorldAccessGuard`) but still exists
- `splash_screen.dart` exists but isn't wired into the router
- Inconsistent loading states across screens (some use shimmer, some use spinners, some have nothing)
- Screen files are large (world_detail_screen.dart is 1028 lines with many private widget classes inline)

## 11. Build & Deploy

```bash
flutter build apk --release   # → 139MB APK
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

Signed with `android/upload-keystore.jks` (RSA 2048). Keystore backup doc at `docs/superpowers/specs/keystore-backup.md`.
