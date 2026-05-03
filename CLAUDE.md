# CLAUDE.md — Vertiege (Flutter App)

## Development Commands

```bash
flutter pub get          # Install dependencies
flutter run              # Run on connected device/emulator
flutter build apk --debug  # Build debug APK
flutter build apk --release # Build release APK
flutter analyze          # Static analysis (0 issues required)
flutter test             # Run all tests
dart format lib/         # Format code
```

## Architecture

Flutter 3.x + Dart 3.11 + Material 3 + Riverpod + GoRouter + Supabase.

### State Management (Riverpod)

| Provider | File | State |
|---|---|---|
| `themeProvider` | `lib/state/theme_provider.dart` | ThemeScheme (system/light/dark) |
| `residentProvider` | `lib/state/resident_provider.dart` | ResidentState (profile + loading) |
| `worldProvider` | `lib/state/world_provider.dart` | WorldState (worlds map + loading) |
| `postProvider` | `lib/state/post_provider.dart` | PostState (posts, bookmarks, error) |
| `chatProvider` | `lib/state/chat_provider.dart` | ChatState (rooms, messages) |
| `notificationProvider` | `lib/state/notification_provider.dart` | NotificationState |
| `achievementProvider` | `lib/state/achievement_provider.dart` | AchievementState |
| `channelProvider` | `lib/state/channel_provider.dart` | ChannelState |
| `eventProvider` | `lib/state/event_provider.dart` | Events |
| `questProvider` | `lib/state/quest_provider.dart` | Quests |

Pattern: `StateNotifier<T>` + `StateNotifierProvider` for mutable state. `Provider<T>` for derived values (e.g., `appRouterProvider`).

### Design Tokens

- **Colors**: `lib/theme/colors.dart` — AppColors with semantic tokens (Discord + Duolingo + Supabase)
- **Design System**: `lib/theme/design_system.dart` — Spacing, RadiusTokens, FontSizes, IconSizes, BorderWidth, ShadowTokens, AnimDurations, AnimCurves
- **Theme**: `lib/theme/app_theme.dart` — Material 3 ThemeData (light + dark), auto-derived from seed `#5865F2`

### Routing

`lib/router/app_router.dart` — GoRouter with auth guard redirects + StatefulShellRoute for 5 tabs:
- `/` Nexus (home feed)
- `/explore` Explore (worlds)
- `/chat` Chats
- `/identity` Identity (profile)
- `/alerts` Alerts (notifications)

### Component Patterns

- All stateful widgets use `ConsumerWidget` or `ConsumerStatefulWidget`
- Always derive style from `Theme.of(context)`, never hardcoded
- Use design tokens: `Spacing.*`, `RadiusTokens.*`, `FontSizes.*`, `IconSizes.*`
- Entrance animations: `FadeIn(delayMs: index * 60~70)`
- Loading states: `Shimmer` / `ShimmerPostCard` / `ShimmerChatTile`
- Empty states: `AppEmptyState` with icon + message + optional CTA
- Error states: `AppErrorState` with retry callback
- Skeleton (old): Use `Shimmer` instead

### Widget Directory

```
lib/widgets/
  core/          — FadeIn, Shimmer, StatusDot, TactileButton, NotificationBell,
                   AppEmptyState, AppErrorState, ImageViewer, ScreenHeader
  feed/          — PostItem, PostInput, ReactionBar, CommentSheet, MediaGrid
  profile/       — CosmeticAvatar, NameBanner, Badge, BadgeDisplay, ShareCard
  worlds/        — WorldCard, WorldBanner, WorldIcon, WorldChannelList,
                   WorldResidents, AccessGuard, Leaderboard
  shared/        — HapticTab, ImagePickerWidget, ProgressBar, SearchBarWidget,
                   TierIcon, ParallaxScroll
  achievements/  — AchievementCard, AchievementGrid, TierCelebration
```

### Asset Conventions

- **World banners**: `assets/generated/world-{id}.jpg` (16 worlds)
- **Avatars**: `assets/generated/avatar-{n}.png` (6 numbered + 3 named)
- **Badges**: `assets/generated/badge-{name}.png` (12 badges)
- **Profession icons**: `assets/generated/prof-{name}.png` (6 professions)
- **Tier images**: `assets/generated/tier-{name}.png` (4 tiers)
- **Backgrounds**: `assets/generated/bg-splash.jpg`, `bg-onboarding.jpg`, `empty-notifications.jpg`
- **SVGs**: `assets/banners/`, `assets/decorations/`, `assets/icons/`

### Config-Driven Data

- **Tiers**: `lib/config/tiers.dart` — tierNames, standingLevels, featureUnlocks, prestige calc, worldsConfig (16 worlds)
- **Cosmetics**: `lib/config/cosmetics.dart` — cosmeticFrames, professionCosmetics, decorationTypes
- **Achievements**: `lib/config/achievements.dart` — achievement definitions

### Figma Integration

Rules file: `.claude/figma-rules.md` — complete token ↔ Figma mapping, component ↔ Flutter widget mapping, layout translation rules.

## Testing

```bash
flutter test                    # All tests
flutter test --name "test name" # Single test
```

## Known Issues

| # | File | Issue |
|---|------|-------|
| 1 | `world_detail_screen.dart` | Resident profile XP shown on other profiles |
| 2 | `chat_provider.dart` | Message IDs collision-prone |
| 3 | `channel_provider.dart` | Stale read-then-write in _persist |
| 4 | `settings_screen.dart` | "Restore Backup" unimplemented |

## Before Committing

- `flutter analyze` must show 0 issues
- No hardcoded hex colors — use `AppColors.*` or `theme.colorScheme.*`
- No hardcoded spacing/radii — use tokens
