# Vertiege v1.0.0-beta.4+1

> A tier-gated social network where every world is a sovereign realm with entry conditions. Built with Flutter + Riverpod + Supabase + Sovereign Excellence dark theme.

<p align="center">
  <img src="assets/generated/avatar-1.png" width="64" />
  <img src="assets/generated/avatar-2.png" width="64" />
  <img src="assets/generated/avatar-3.png" width="64" />
  <img src="assets/generated/avatar-4.png" width="64" />
  <img src="assets/generated/avatar-5.png" width="64" />
  <img src="assets/generated/avatar-6.png" width="64" />
</p>

---

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Screens](#screens)
- [Widgets](#widgets)
- [State & Providers](#state--providers)
- [Services](#services)
- [Models](#models)
- [Theme & Design System](#theme--design-system)
- [Router](#router)
- [Configuration](#configuration)
- [Utilities](#utilities)
- [Features](#features)
- [Tier & Standing Systems](#tier--standing-systems)
- [World Types & Access](#world-types--access)
- [Getting Started](#getting-started)
- [Build & Release](#build--release)
- [License](#license)

---

## Overview

Vertiege is a semi-social, semi-gamified sovereign realm platform. Users create residents, join tier-gated worlds, earn prestige through activity, and ascend through five tiers — from Hustler to Apex.

**290 Dart files** across **11 directories**.

| Category | Count |
|----------|-------|
| Screens | 46 |
| Widgets | 110 |
| State Providers | 14 |
| Services | 49 |
| Models | 31 |
| Theme | 7 |
| Router | 1 |
| Config | 5 |
| Utils | 13 |
| Repositories | 4 |
| UI | 8 |
| Widgets | 93 |
| State Providers | 10 |
| Services | 26 |
| Models | 12 |
| Theme | 3 |
| Router | 1 |
| Config | 4 |
| Utils | 8 |

---

## Architecture

```
lib/
├── main.dart                          # Entry: dotenv, gate status, Supabase init with HTTP timeouts
├── app.dart                           # VirtualStatusWorldsApp: splash → background loads → router
├── config/
│   ├── achievements.dart              # 90 achievements across 13 categories
│   ├── cosmetics.dart                 # Avatar frames, decorations, prestige badges
│   ├── tiers.dart                     # 7 standing levels, tier names, world level thresholds, worldsConfig (14 default worlds)
│   └── titles.dart                    # Earned title map (achievement ID → display title)
├── models/
│   ├── achievement.dart               # Achievement, AchievementCategory (13), AchievementStatus
│   ├── alliance.dart                  # Alliance between two worlds
│   ├── channel.dart                   # WorldChannel, ChannelType (text/announcement/feed)
│   ├── event.dart                     # WorldEvent with RSVP tracking
│   ├── invite.dart                    # WorldInvite with code, uses, expiration
│   ├── message.dart                   # ChannelMessage for channel + DM
│   ├── notification.dart              # AppNotification, NotificationType (9 types)
│   ├── post.dart                      # Post, Comment, reactions map
│   ├── report.dart                    # Report, ReportReason (6), ReportStatus
│   ├── resident.dart                  # Resident, ResidentTier (1-5), WorldStanding, VerificationStatus
│   ├── season.dart                    # Season, SeasonWorldScore, composite scoring
│   └── world.dart                     # World, WorldType (wealth/profession/dominion), WorldConstitution, WorldFeatures, DominionWorld
├── repositories/                      # (4) Data access layers wrapping Supabase/APIs
├── router/
│   └── app_router.dart                # GoRouter Provider: 25+ routes, auth/tier redirect guards
├── screens/                           # (46) Full-page Flutter UI screens
├── services/                          # (49) Business logic and third-party integrations
├── state/                             # (14) Riverpod providers and state models
├── theme/                             # (7) Design tokens, colors, and global theming
├── ui/                                # (8) Reusable, generic UI components
├── utils/                             # (13) Helper functions, formatters, generators
└── widgets/                           # (110) Specific feature components divided by domain
```

---

## Screens

### Auth (3 screens)

| Screen | Route | Description |
|--------|-------|-------------|
| LoginScreen | `/login` | Email/password login with glass panels, tactile buttons, auth error card |
| SignUpScreen | `/signup` | Email/password sign-up creating a new Supabase auth user |
| AuthCallbackScreen | `/auth/callback` | Post-authentication transitional screen with gradient background and loading indicator |

### Onboarding (2 screens)

| Screen | Route | Description |
|--------|-------|-------------|
| OnboardingScreen | `/onboarding` | Profile setup: picks avatar image, enters display name, creates initial resident record |
| TheGateScreen | `/the-gate` | Immersive 3-step intro: cosmic background, tier reveal, world path selection, marks gate completion for routing |

### Tab Screens (7 screens + 1 layout)

| Screen | Route | Description |
|--------|-------|-------------|
| TabLayout | — | 4-tab bottom navigation shell (Nexus, Explore, Chat, Identity) with notification badge and quick-post FAB |
| NexusScreen | `/` | Main feed: luminary nameplate greeting, bento grid (5 cards: prestige, quests, season, trending, feed preview), tab/sort controls, post list with infinite scroll, scroll-to-top FAB |
| ExploreScreen | `/explore` | World discovery: search bar, season banner, filter pills (All/Wealth/Profession/Dominion), featured worlds row, boosted realms row, trending/rising sections, view mode toggle (Grid/Tier/List), 2-column grid |
| ChatListScreen | `/chat` | DM list: glass cards with cosmetic avatars, status dots, time-ago stamps, unread badges, New Chat button, Explore Worlds CTA on empty state |
| IdentityScreen | `/identity` | Current user profile: hero avatar with gold glow, luminary nameplate, tier icon, subscription badge, streak display, bio, Edit Profile + Share buttons, achievement grid, referral chip, sign out |
| CreatePostScreen | `/create-post` | Post composer with ghost input, image picker, and world selector |
| AlertsScreen | `/notifications` | Notification feed grouped by today/this week/earlier with fade-in animation |

### World Screens (6 screens)

| Screen | Route | Description |
|--------|-------|-------------|
| WorldDetailScreen | `/explore/:worldId` | Master world view: full-bleed procedural banner with tier glow, hero section with world name/sovereign/stats, info cards (members/posts/events), live chat preview, resource vault, alliances section, tab bar (Feed/Channels/Members), join/leave with pulse animation |
| WorldChannelScreen | `/explore/:worldId/:channelName` | Channel chat: message grouper with date separators, message bubbles (sent/received/system), chat images, glass input bar with send button, scroll-to-bottom FAB |
| WorldSettingsScreen | `/explore/:worldId/settings` | Sovereign management: edit name/description/constitution, manage channels (add/edit/delete/reorder), invite management, boost via IAP |
| WorldMembersScreen | `/explore/:worldId/members` | Member roster: search, standing levels with tier colors, sovereign badges, rep values, profile navigation, error state with retry |
| CreateWorldScreen | `/create-world` | World creation: name, type selector (wealth/profession/dominion), icon picker, description, constitution editor, subscription gate for tier-restricted creation |
| SearchScreen | `/search` | Global search: recent searches, world results with cards, resident results with avatars, debounced query with clear button |

### Other Screens (9 screens)

| Screen | Route | Description |
|--------|-------|-------------|
| SplashScreen | `/splash` | Animated splash: scaling gold globe icon, fade-in Vertiege title, tagline, pulsing loader, procedural decorative shapes (4 positioned glass shapes) |
| SettingsScreen | `/settings` | App settings: theme mode toggle, text size slider, notification preferences, backup/restore data, sign out, delete account |
| ResidentProfileScreen | `/residents/:id` | Other resident's profile: cosmetic avatar, luminary nameplate, tier standing, achievements list, DM entry point, follow/unfollow |
| ChatRoomScreen | `/chat/:roomId` | Full DM chat: message grouper with date separators, glass-style bubbles, image sharing/attachment, typing indicator (3 bouncing dots), image preview bar, scroll FAB |
| CosmeticsShopScreen | `/shop` | Cosmetics marketplace: frames, badges, nameplate styles as unlockable items |
| SeasonScreen | `/season` | Season leaderboard: current season name/dates, top worlds ranked by composite score with trend indicators (up/down arrows) |
| SubscriptionScreen | `/subscription` | Subscription tiers (Resident/Patrician/Sovereign Elite) with benefits comparison and IAP purchase buttons |
| HallOfAscensionScreen | `/hall-of-ascension` | Achievement leaderboard: XP-ranked residents with luminary nameplates and avatars, prestige leaderboard for worlds (sample data gated to debug mode) |
| VerificationReviewScreen | `/admin/verifications` | Admin panel: list of pending verification submissions, approve/reject with reviewer notes |
| AscensionPathScreen | `/ascension-path` | Tier progress visualization: 5-step trail (Hustler→High Roller→Elite→Old Money→Apex) with XP thresholds and milestone checkpoints |

---

## Widgets

### Core (22 widgets)

| Widget | Purpose |
|--------|---------|
| GlassPanel | Reusable frosted-glass container with configurable blur, borders, padding, rounded corners |
| GlassSheet | Glass-morphism bottom sheet with blur overlay, gold drag handle |
| SovereignCard | Tier-aware card wrapper: GlowBorder (Apex) or GlassPanel (lower tiers) |
| GlowBorder | Tier-colored glow effect border (Apex gold, Elite violet, Hustler orange) |
| FadeIn | Entrance animation: fade + slide + optional scale with configurable delay/duration/curve, 2s fallback |
| Shimmer / Pulse | Skeleton loading animations for placeholders |
| EmptyState / AppEmptyState | Branded animated empty state with icon, message, optional CTA button |
| GlassLoadingList / ScreenLoading | Full-screen skeleton loaders: feed, list, grid, profile, detail variants |
| ErrorBanner | Sovereign-styled error with code label, message, retry button |
| NotificationBell | Bell icon with unread count badge, animated pulse |
| GhostInput | Styled text input with glass border and accent colors |
| TactileButton | Duolingo-inspired pressable button with 3px drop animation |
| StatusDot | Discord-style presence dot (online/idle/dnd/offline) |
| SovereignStat | Icon + value + label stat in glass panel |
| XpToast | Overlay-based XP gain toast: slides up, bounces, shows "+XP", fades out |
| DailyRewardDialog | Celebratory glass-modal for daily reward collection |
| ProtocolLogs | Read-only glass panel with monospace log entries |
| ImageViewer | Full-screen image viewer with hero animation and dismiss gesture |
| OfflineBanner | Conditional banner when connectivity is lost |
| ContextualChips | Dynamic chip row for contextual actions (tips, quests, invites) |
| SafeAsyncBuilder | Generic async UI: loading/error/empty/data states in one widget |
| SovereignProgressBar | Thin 4px progress bar with current/max and tier accent |

### Worlds (21 widgets)

| Widget | Purpose |
|--------|---------|
| WorldCard | Compact card for explore grid: banner, icon, name, prestige, member count, tier badge, lock badge |
| WorldBanner | Procedural banner generated deterministically from world ID |
| WorldHeroBanner | Expandable hero with scroll parallax, join button, settings gear |
| WorldIcon | Frosted-glass icon container from WorldAssets |
| WorldInfoSheet | Bottom sheet: description, stats, quick actions |
| WorldInfoCards | Stat trio (members, posts, events) for detail header |
| WorldChannelList | Vertical clickable channel tiles |
| WorldResidents | Paginated member list with avatars |
| WorldEventsCard | Calendar-styled upcoming events (next 3) |
| WorldFeedTab | Combined feed: post input + post/event list |
| WorldDetailMembers | Members tab: leaderboard, rows, events, residents |
| WorldMemberRow | Horizontal scrollable member avatars with rep/tier |
| EventCard | Glass card: event title, date/time, RSVP action |
| Leaderboard | Top members by reputation with rank/avatar/rep |
| AccessIcon | Lock/unlock/denied icon with semantic colors |
| WorldAccessGuard | Gate widget: checks tier/profession against world requirements |
| WorldShareCard | 9:16 story-format share card with procedural banner |
| BannerGenerator | AI-assisted banner generator (4 procedural variants) |
| ResourceVault | Glass placeholder for world resource storage (Elder+ gated) |
| AllianceSection | Allied worlds display with navigation |
| ChatPreviewPanel | Recent messages preview for a world |

### Profile (11 widgets)

| Widget | Purpose |
|--------|---------|
| CosmeticAvatar | Avatar resolver (file/network/asset) with cosmetic frame overlay |
| LuminaryNameplate | Tier-aware name renderer: plain text → animated gold-violet gradient with glow |
| Badge | Chip badge for a single earned decoration |
| BadgeDisplay | Horizontal wrap of multiple earned badges |
| NameBanner | Small name+profession near avatars in post/comment contexts |
| ShareCard | Glass export card: avatar, nameplate, tier, XP |
| AchievementShareCard | Glass export card for newly earned achievements |
| CompletionHint | Tap target toggling "share"/"copied" with haptic feedback |
| ReferralChip | Referral code as copy-to-clipboard chip |
| SubscriptionBadge | Tier badge (Resident/Patrician/Sovereign Elite) |
| StreakDisplay | Streak counter with fire icon, milestones, shields |

### Feed (7 widgets)

| Widget | Purpose |
|--------|---------|
| PostItem | Full post card: author avatar, nameplate, content, image, timestamp, comments, reactions, tier icon, report/share |
| PostComposer | In-world post composer with text + image + XpToast on submit |
| PostInput | Compact post input bar for quick posting |
| PostImage | Network image with shimmer placeholder and rounded corners |
| CommentSheet | Comment list with text input for new comments |
| MediaGrid | Optimized image grid (1/2/3+ images) |
| ReactionBar | Emoji reaction chips with haptic and burst animation |

### Nexus (9 widgets)

| Widget | Purpose |
|--------|---------|
| BentoGrid | Responsive wrap layout for BentoCard children |
| FeedTabChip | Tab chip (All/Following/Announcements) |
| FeedSortDropdown | Sort dropdown (Latest/Hot/Top) |
| WorldInviteSection | Pending world invite cards with accept/decline |
| DailyQuestCard | Small bento: daily quest progress |
| PrestigeProgressCard | Medium bento: tier name + XP bar |
| SeasonSnapshotCard | Small bento: season name + world count |
| TrendingCard | Large bento: 3 trending worlds |
| FeedPreviewCard | Large bento: 2 recent posts + View All link |

### Explore (8 widgets)

| Widget | Purpose |
|--------|---------|
| TierSection | Model: groups worlds by tier with title + color |
| SectionHeader | Gold bar + Space Grotesk section heading |
| ViewModeToggle | Toggle button for Grid/Tier/List modes |
| FeaturedWorldsRow | Horizontal scroll of featured world cards |
| BoostedWorldsRow | Horizontal scroll of boosted world cards |
| TrendingRisingSection | Section with HOT/NEW badge and horizontal world cards |
| ShimmerWorldCard | Placeholder shimmer matching WorldCard dimensions |
| SeasonBanner | Season name, dates, world count with gold CTA |

### Chat (5 widgets)

| Widget | Purpose |
|--------|---------|
| ChatMessageGrouper | Groups raw messages into ChatDisplayItem (date separator, first/subsequent) |
| ChatDateSeparator | Centered date label with horizontal rules |
| ChatInputBar | Glass input: send button + optional attachment icon |
| ChatImage | Network/local image bubble with rounded corners |
| ScrollFab | Scroll-to-bottom floating action button |

### Achievements (3 widgets)

| Widget | Purpose |
|--------|---------|
| AchievementCard | Single achievement: icon, title, description, XP, status, AI confidence |
| AchievementGrid | Grid of achievement cards with category headers |
| TierCelebration | Full-screen overlay celebration for tier-up with particle effects |

### Shared (5 widgets)

| Widget | Purpose |
|--------|---------|
| TierIcon | Tier 1-5 → Material icon with corresponding color |
| ProgressBar | Fill-based bar with current/max, label, tier accent |
| ShareButton | RepaintBoundary wrapper: captures child as PNG → native share sheet |
| FilterPill | Glass-style selectable chip with icon + label |
| ImagePickerWidget | Gallery image picker returning file path |

### Auth (1 widget)

| Widget | Purpose |
|--------|---------|
| AuthErrorCard | Red-tinted error container for auth forms |

### Journey (1 widget)

| Widget | Purpose |
|--------|---------|
| ProgressTrail | 5-step tier trail (Hustler→Apex) with filled/unfilled dots and connecting lines |

---

## State & Providers

All 10 providers use Riverpod `Notifier`/`NotifierProvider` pattern with `copyWith` on immutable state classes.

| Provider | State Class | Key Fields | Persistence |
|----------|------------|------------|-------------|
| residentProvider | ResidentState | resident, isLoading, verificationStatus | SharedPreferences (immediate write) |
| worldProvider | WorldState | worlds (14 default), isLoading, alliances | SharedPreferences |
| postProvider | PostState | posts, bookmarkedPostIds, error | SharedPreferences |
| chatProvider | ChatState | dmRooms, dmMessages, channelMessages, isLoadingRooms | In-memory |
| channelProvider | ChannelState | channelsByWorld, worldChannelIds | SharedPreferences |
| eventProvider | EventState | eventsByWorld, rsvp | SharedPreferences |
| notificationProvider | NotificationState | notifications, unreadCount | SharedPreferences |
| achievementProvider | AchievementState | userAchievements, totalXp, currentTier, celebration | SharedPreferences |
| questProvider | QuestState | dailyQuests, streak, completedAt | SharedPreferences |
| themeProvider | ThemeState | themeMode | SharedPreferences |

---

## Services

26 services handling backend communication, business logic, and persistence.

### Backend Services (Supabase)

| Service | Supabase Table | Operations |
|---------|---------------|------------|
| auth_service | auth.users | signInWithEmail, signUpWithEmail, signInWithOtp, signOut, getSession |
| profile_service | profiles | upsert, get, search, getTopResidents |
| world_service | worlds, world_members | create, loadWorlds, joinWorld, leaveWorld |
| post_service | posts | create (with moderation), getPosts, addReaction, addComment |
| chat_service | dm_rooms, dm_messages, channel_messages | getOrCreateRoom, sendMessage, getMessages, getChannelMessages |

### Business Logic

| Service | Purpose |
|---------|---------|
| access_control | `canAccessWorld()`: checks tier, profession, unlocked list |
| permission_service | Standing-based action gating: canPost, canDelete, canInvite, canModerate |
| moderation_filter | 3-stage pre-publish filter: profanity word list → keyword heuristics → spam detection |
| moderation_service | Server-side ban/mute/warn with moderation_logs |
| prestige_service | World prestige scoring from member count, tier, posts, standing |
| season_service | Season data generation + rankings |
| daily_reward_service | Daily XP/shield reward generation and last-claim tracking |
| verification_service | Profession proof upload (10MB cap, jpg/png/pdf) + submit/approve/reject |
| ai_verification_service | Simulated AI proof analysis with confidence scores |
| council_service | Council member tracking and governance logging |
| invite_service | World invite create/lookup/accept with code generation |
| legacy_service | Maps legacy tier system to new colors/labels |

### Infrastructure

| Service | Purpose |
|---------|---------|
| supabase | `getSupabase()` client accessor + `isSupabaseConfigured()` gate |
| storage_service | SharedPreferences wrapper: setString, getString, setStringDebounced, remove, getAll |
| secure_storage_service | FlutterSecureStorage for auth tokens (userId, accessToken, refreshToken) |
| cache_service | Feed/world cache for instant-resume UX |
| backup_service | JSON export/import of all SharedPreferences keys |
| store_service | IAP wrapper: buyWealthTier, buyWorldBoost, restorePurchases, loadProducts |
| subscription_service | Tier management (Resident/Patrician/SovereignElite) with per-resident key |
| crash_reporter | Crash reporting abstraction (ConsoleCrashReporter default, FirebaseCrashlytics ready) |

---

## Models

12 model classes with enums, serialization, and business logic.

| Model | Key Enums | Serialization |
|-------|-----------|---------------|
| Resident | ResidentTier (5 levels), VerificationStatus | fromJson/toJson/fromSupabase |
| World | WorldType (wealth/profession/dominion) | toJson/fromJson/fromSupabase |
| WorldConstitution | — | toJson/fromJson (nested in World) |
| Post | — | fromJson/toJson |
| Comment | — | fromJson/toJson |
| ChannelMessage | — | fromSupabase |
| WorldChannel | ChannelType (text/announcement/feed) | fromSupabase |
| AppNotification | NotificationType (9 types) | fromSupabase/toSupabase |
| Achievement | AchievementCategory (13), AchievementStatus (4) | — |
| WorldEvent | — | — |
| Season | — | — |
| Alliance | — | — |
| WorldInvite | — | fromSupabase |
| Report | ReportReason (6), ReportStatus (3) | — |

---

## Theme & Design System

### Sovereign Excellence — Dark Only

| Token Category | Values |
|----------------|--------|
| Surface | OLED obsidian: `#0A0A0B` (canvas), `#131316` (surface), `#1A1A1E` (surfaceContainer) |
| Primary | Sovereign violet: `#8B7CF6` → `#A78BFA` |
| Tertiary | Gold: `#D4A843` → `#F0C969` |
| Ink | `#F4F4F5` (primary), `#A1A1AA` (secondary), `#71717A` (muted) |
| Semantic | `#EF4444` (error), `#22C55E` (success), `#F59E0B` (warning) |
| Tier Colors | Hustler `#F97316` (orange) → Elite `#8B7CF6` (violet) → Apex gold gradients |
| Fonts | Space Grotesk (headlines), Inter (body), JetBrains Mono (code) |
| Spacing Scale | 4, 6, 8, 10, 12, 16, 20, 24, 32, 40 |
| Radius Scale | 4, 6, 8, 10, 12, 16, 20, 24, 9999 (pill) |

### Glass Tokens

| Token | Value |
|-------|-------|
| Background Alpha | 0.55 |
| Border Alpha | 0.12 |
| Blur Sigma | 12 |
| Gold Glow Alpha | 0.06 |

---

## Router

GoRouter as a Riverpod Provider with auth redirect guard.

### Route Map

| Path | Screen | Access |
|------|--------|--------|
| `/splash` | SplashScreen | Public |
| `/login` | LoginScreen | Public |
| `/signup` | SignUpScreen | Public |
| `/auth/callback` | AuthCallbackScreen | Public |
| `/onboarding` | OnboardingScreen | Auth required, no resident |
| `/the-gate` | TheGateScreen | Auth + resident, gate not completed |
| `/` | NexusScreen | Full access |
| `/explore` | ExploreScreen | Full access |
| `/explore/:worldId` | WorldDetailScreen | Tier-gated |
| `/explore/:worldId/:channelName` | WorldChannelScreen | World member |
| `/explore/:worldId/settings` | WorldSettingsScreen | Sovereign/Council |
| `/explore/:worldId/members` | WorldMembersScreen | World member |
| `/chat` | ChatListScreen | Full access |
| `/chat/:roomId` | ChatRoomScreen | Full access |
| `/identity` | IdentityScreen | Full access |
| `/notifications` | AlertsScreen | Full access |
| `/search` | SearchScreen | Full access |
| `/create-post` | CreatePostScreen | Full access |
| `/create-world` | CreateWorldScreen | Tier 2+ |
| `/settings` | SettingsScreen | Full access |
| `/residents/:id` | ResidentProfileScreen | Full access |
| `/achievements` | AchievementsIndexScreen | Full access |
| `/achievements/:category` | AchievementCategoryScreen | Full access |
| `/achievements/submit` | SubmitAchievementScreen | Full access |
| `/subscription` | SubscriptionScreen | Tier 2+ |
| `/season` | SeasonScreen | Full access |
| `/shop` | CosmeticsShopScreen | Full access |
| `/hall-of-ascension` | HallOfAscensionScreen | Full access |
| `/ascension-path` | AscensionPathScreen | Full access |
| `/admin/verifications` | VerificationReviewScreen | Tier 4+ (Admin) |
| `/invite/:code` | InviteAcceptScreen | Auth required |

### Redirect Logic

```
No session → /login
Session, no resident → /onboarding
Session + resident, gate not done → /the-gate
Tier < 4, /admin/* → /
Tier < 2, /create-world → /
Tier < 2, /subscription → /
On auth/onboarding/gate pages, fully authenticated → /
```

---

## Configuration

| File | Contents |
|------|----------|
| tiers.dart | Tier names (Hustler-1 → Apex-5), 7 standing levels (Visitor→Council), world level thresholds (1-10), worldsConfig (14 default worlds with tier/profession requirements) |
| achievements.dart | 90 achievements across 13 categories, xpThresholds (500/2000/10000/50000), getTierForXp() |
| titles.dart | Earned title map: achievement ID → display title ("the Storyteller", "the Eternal", etc.) |
| cosmetics.dart | CosmeticFrame definitions, decorationLabels, prestigeBadges |

---

## Utilities

| Utility | Purpose |
|---------|---------|
| date_format | Delegates to timeAgo() for relative timestamps |
| time_ago | "just now", "5m ago", "3h ago", "2d ago", "1w ago", "3mo ago", "2y ago" + TimeAgo widget (auto-updating) |
| tier_utils | Maps standing level (1-7) to tier-appropriate display colors |
| text_parser | Extracts @mentions and #hashtags from post/channel text |
| haptics | light(), medium(), heavy(), selection(), doubleTap() presets |
| id_generator | UUID v4 via uuid package |
| world_assets | Deterministic accent color, Material icon, pattern params from world ID hash |
| string_utils | capitalize(), truncate() helpers |

---

## Features

### World Discovery
- 14 built-in worlds: 5 Tier-gated Wealth, 6 Profession-gated, 3 open-access
- Grid, Tier (Apex/Elite/Hustler), and List view modes
- Search with debounce, filter pills by world type
- Season banner with current season name and rankings link
- Featured worlds row (top 5 by prestige)
- Trending/Rising sections with velocity scoring
- World detail: procedural banner, tabs (Feed/Channels/Members), join/leave
- Starter Worlds Auto-Join: New residents are automatically added to default starter worlds.
- Wealth World Level-Up Access: Wealth Worlds can be unlocked for free when a resident's Tier matches or exceeds the required level, presented with a progress breakdown.

### Social Feed
- Post creation with text + image + announcement toggle
- Feed filtering: All / Following / Announcements
- Sort modes: Latest / Hot (by reactions) / Top (by comments)
- Reactions: thumbs up, heart, fire, celebrate with haptic
- Comments: modal bottom sheet with submission
- Post pinning, announcements, delete/report

### Chat & Messaging
- Direct Messages: 1:1 rooms with real-time messaging
- World Channels: per-world channel messaging
- Message grouping: date separators, sender grouping (5-min window)
- Image sharing with preview
- Typing indicator (bouncing dots)
- Scroll-to-bottom FAB

### Tier & Progression
- 5 tiers: Hustler → High Roller → Elite → Old Money → Apex
- XP from posts, reactions, achievements, daily quests
- Tier thresholds: 0, 500, 2000, 10000, 50000
- 7 standing levels per world: Visitor → Member → Contributor → Veteran → Elder → Patron → Council
- Reputation from world activity
- Daily quests: 4 rotating tasks with XP rewards
- Streak tracking with shields and milestone bonuses
- 90 achievements across 13 categories
- Achievement verification with proof submission
- Ascension path: visual 5-step tier trail
- Real-World Achievements: Users can submit real-world proof for achievements to gain XP and levels.

### Monetization
- Wealth world tiers purchasable via IAP
- World boosts (consumable)
- Subscription tiers: Resident (free), Patrician, Sovereign Elite
- Each tier: world limits, streak shields, priority verification, gold name, custom background, analytics, badge
- Shop Expansions: XP Boosters and Extra World Slots can be purchased with Sovereign Coins.

### Moderation
- 3-stage content filter: profanity → patterns → spam
- Server-side ban/mute/warn
- Report system: 6 reasons (spam, harassment, hate speech, NSFW, misinformation, other)
- Admin verification review panel
- Admin Dashboard/Verification: Dedicated dashboard for admins to review and approve real-world proofs, which automatically assigns verified roles.
- Sovereign Level-Gate: To ensure meaningful progression, creating a new Sovereign World requires reaching Tier 3 (Elite) and 2000 XP.

### Cosmetics & Identity
- Cosmetic avatar frames
- Luminary nameplates with tier-based visual treatment
- Badges and decorations
- Subscription badges
- Streak display with milestone tracking
- Referral codes
- Shareable profile and achievement cards

### Seasons
- 4-week world competitions
- Composite scoring: posts, reactions, new members, events, channel activity
- Podium rankings with trend indicators
- Season leaderboard screen

---

## Tier & Standing Systems

### Resident Tiers (Global)

| Tier | Name | XP Required | Visual |
|------|------|-------------|--------|
| 1 | Hustler | 0 | Plain text, orange accent |
| 2 | High Roller | 500 | SemiBold, violet primary |
| 3 | Elite | 2,000 | Bold, subtle glow |
| 4 | Old Money | 10,000 | Gold text, pronounced glow |
| 5 | Apex | 50,000 | Animated gold-violet gradient |

### World Standing (Per-World)

| Level | Title | Rep | Unlocks |
|-------|-------|-----|---------|
| 1 | Visitor | 0 | View |
| 2 | Member | 10 | Post, react, comment |
| 3 | Contributor | 50 | Images, polls, delete own |
| 4 | Veteran | 200 | Lounge |
| 5 | Elder | 500 | Vault, gift |
| 6 | Patron | 1,000 | Invite others |
| 7 | Council | 5,000 | Moderate (delete any, mute, ban) |

### World Levels (Dominion)

| Level | Activity Score | Resident Capacity |
|-------|---------------|-------------------|
| 1 | 0 | 10 |
| 5 | 1,000 | 50 |
| 10 | 10,000 | 500 |

### World Prestige (0-50)

| Range | Tier Name | Glow Color |
|-------|-----------|------------|
| 0-19 | Hustler | Orange |
| 20-39 | Elite/High Roller | Violet |
| 40-50 | Apex | Gold |

---

## World Types & Access

### 14 Default Worlds

| World | Type | Requirement |
|-------|------|-------------|
| Neon District | Wealth | Tier 1 (Hustler) |
| Crystal Shore | Wealth | Tier 1 (Hustler) |
| Azure Coast | Wealth | Tier 2 (High Roller) |
| Crimson Court | Wealth | Tier 2 (High Roller) |
| Sovereign City | Wealth | Tier 3 (Elite) |
| Golden Estate | Wealth | Tier 4 (Old Money) |
| Aetheria | Wealth | Tier 5 (Apex) |
| Nova Station | Wealth | Tier 5 (Apex) |
| Aviation Heights | Profession | Verified Aviation role |
| Medical Nexus | Profession | Verified Medical role |
| Financial District | Profession | Verified Finance role |
| Tech Sprawl | Profession | Verified Technology role |
| Legal Plaza | Profession | Verified Legal role |
| Arts Pavilion | Profession | Verified Arts role |
| Quantum Core | Profession | Verified Engineer role |
| Silver Page | Profession | Verified Artist role |

### Access Rules
- **Wealth worlds**: `resident.tier >= world.requiredTier` OR world is in `resident.wealthWorldsUnlocked`
- **Profession worlds**: `resident.verifiedRoles` contains the profession OR an alias
- **Dominion worlds**: Invite-only, open to all once joined

---

## Tech Stack

| Category | Technology |
|----------|-----------|
| Framework | Flutter 3.41 (Dart 3.11) |
| State | Riverpod 2.6 (Notifier + NotifierProvider) |
| Routing | GoRouter 14.8 (StatefulShellRoute) |
| Backend | Supabase 2.8 (Auth, Database, Realtime, Storage) / supabase_flutter |
| Local Storage | SharedPreferences + FlutterSecureStorage |
| UI | Material 3 Dark-Only + Custom Glass Design System |
| Fonts | Google Fonts (Space Grotesk, Inter) |
| Live Audio/Video | livekit_client 2.5.3 |
| IAP | in_app_purchase 3.2 |
| Images | image_picker 1.1 |
| Share | share_plus 10.1 |
| IDs | uuid 4.5 |

---

## Getting Started

```bash
# Clone
git clone https://github.com/Immabe96/Vertiege.git
cd Vertiege

# Configure environment
cp .env.template .env
# Edit .env with your Supabase URL and anon key:
#   SUPABASE_URL=https://your-project.supabase.co
#   SUPABASE_ANON_KEY=your-anon-key

# Install dependencies
flutter pub get

# Run
flutter run
```

### Prerequisites
- Flutter SDK 3.x (stable channel)
- Dart 3.11+
- Android Studio / Xcode
- Supabase project (for remote features; app works offline with local worlds)

---

## Build & Release

### Development
```bash
flutter run                          # Debug on connected device
flutter build apk --debug            # Debug APK
```

### Release (Play Store)
```bash
# Generate keystore (one-time):
keytool -genkey -v -keystore android/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# Create android/key.properties:
#   storePassword=<password>
#   keyPassword=<password>
#   keyAlias=upload
#   storeFile=upload-keystore.jks

flutter build apk --release          # Signed release APK (145MB)
flutter build appbundle --release    # Play Store AAB
```

### CI/CD
GitHub Actions workflow at `.github/workflows/ci.yml`:
- `flutter analyze` (lint gate)
- `flutter test` (47 tests)
- `flutter build apk --debug`

---

## License

MIT
