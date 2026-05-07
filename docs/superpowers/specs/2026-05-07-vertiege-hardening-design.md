# Vertiege App Hardening — Design Spec

**Date:** 2026-05-07
**Approach:** B — Incremental, atomic commits per batch
**Order:** Architecture → Safety → Features → Polish

## Architecture Decisions

### StateNotifier → Notifier Migration

All 10 providers migrate from deprecated `StateNotifier`/`StateNotifierProvider` to `Notifier`/`NotifierProvider`. The `Notifier` API removes the separate state class indirection — methods return the new state directly, and Riverpod handles immutable state comparison.

**Pattern (before → after):**
```dart
// Before: Separate state class + notifier
class ResidentState { ... }
class ResidentNotifier extends StateNotifier<ResidentState> { ... }
final residentProvider = StateNotifierProvider<ResidentNotifier, ResidentState>(...);

// After: Single Notifier class
class ResidentNotifier extends Notifier<ResidentState> {
  @override ResidentState build() => ResidentState();
}
final residentProvider = NotifierProvider<ResidentNotifier, ResidentState>(ResidentNotifier.new);
```

**Migration order (simplest → most complex):**
1. ThemeProvider (50 lines, no deps)
2. QuestProvider (179 lines, no deps)
3. EventProvider (100 lines, no deps)
4. ChannelProvider (170 lines)
5. NotificationProvider (183 lines)
6. AchievementProvider (374 lines, imports resident)
7. PostProvider (517 lines, 5 imports)
8. WorldProvider (336 lines)
9. ResidentProvider (618 lines, 4 imports)
10. ChatProvider (227 lines)

### Screen Decomposition

Each oversized screen splits into extracted widgets following existing patterns in `lib/widgets/`:

| Screen | Lines | Split Into |
|--------|-------|------------|
| identity_screen.dart | 1512 | `identity/` — `profile_card.dart`, `achievement_grid.dart`, `title_display.dart`, `cosmetic_picker.dart` |
| world_detail_screen.dart | 1440 | `worlds/` — `world_header.dart`, `world_stats.dart`, `world_council.dart`, `world_sections.dart` |
| explore_screen.dart | 1182 | `explore/` — `world_card.dart`, `filter_bar.dart`, `trending_section.dart` |
| nexus_screen.dart | 790 | `nexus/` — `bento_grid.dart` (exists), `leaderboard_card.dart`, `nexus_header.dart` |

### Chat Deduplication

`world_channel_screen.dart` and `chat_room_screen.dart` share ~60% code. Extract shared components:
- `widgets/chat/chat_message_list.dart` — message grouping, date separators, animation tracking
- `widgets/chat/chat_input_bar.dart` — compose field, send button, attachment picker
- `widgets/chat/scroll_fab.dart` — jump-to-bottom FAB

### Error Boundaries

A `SafeAsyncBuilder` widget wraps all screens with network calls. Pattern: if a Future/Stream errors during build, catch and render `AppErrorState` (already exists at `widgets/core/empty_state.dart`).

### CI/CD

Single GitHub Actions workflow: `flutter analyze` → `flutter test` → `flutter build apk --debug`. Enforces lint gate before build.

## Critical Fixes Detail

### Compile Fix
- `lib/utils/id_generator.dart:3` — `const Uuid()` → `final Uuid()`

### Data Loss Fixes
- `lib/models/world.dart` — Add `constitution` to `toJson()`, `fromJson()`, `fromSupabase()`
- `lib/config/titles.dart` — Remove `apex-founder`, fix `realm-elder` → `streak-365`
- `lib/models/notification.dart` — Add `created_at` to `toSupabase()`

### Auth Fixes
- `lib/services/auth_service.dart` — Replace `.then()/.catchError()` with `await` in signIn/signUp
- Return typed errors instead of swallowing

### Service Fixes
- `lib/services/profile_service.dart` — `.single()` → `.maybeSingle()` + null check
- `lib/services/verification_service.dart` — Add 10MB cap, extension allowlist [jpg, png, pdf]
- `lib/services/post_service.dart` — Call `ModerationFilter.checkContent()` before insert
- `lib/services/subscription_service.dart` — Key by `residentId`: `'subscription_tier_$residentId'`
- `lib/utils/world_assets.dart` — Fix glow thresholds to match actual prestige range (0-50)
- `lib/services/moderation_filter.dart` — Document as placeholder; add TODO for real moderation API
- `lib/services/store_service.dart` — Gate on `_store.isAvailable()` not `!kDebugMode`

### UI Fixes
- `lib/screens/world_detail_screen.dart` — Move `_estimateCacheSize()` out of build
- `lib/screens/hall_of_ascension_screen.dart` — Gate sample data behind `kDebugMode`
- Add `mounted` checks after all async gaps in screen files
- Add error state rendering to `world_members_screen.dart`, `resident_profile_screen.dart`, `chat_room_screen.dart`

### Duplication Fixes
- Extract identical post sort logic from `post_provider.dart:390-415`
- Extract identical Realtime subscription pattern from `chat_provider.dart:98-196`
- Extract icon choices to shared constant in `lib/theme/`

## New Features

### 1. Push Notifications (Firebase Cloud Messaging)
- `firebase_messaging` integration in `notification_service.dart`
- Supabase Edge Function to push on: new message, new post, reaction, council event
- Permission request on first launch
- Deep link from notification to relevant screen

### 2. Crash Reporting (Sentry)
- `sentry_flutter` integration
- Capture all 41 currently-silent `catch(_){}` blocks
- Breadcrumbs for navigation and auth events
- Release tracking for APK builds

### 3. Enhanced Lint Rules
Enable in `analysis_options.yaml`: `prefer_const_constructors`, `require_trailing_commas`, `use_key_in_widget_constructors`, `avoid_redundant_argument_values`, `unnecessary_lambdas`, `prefer_single_quotes`

### 4. Real Moderation Foundation
- Replace keyword-only filter with a structured moderation pipeline
- Profanity filter using `profanity_filter` package as first pass
- Moderation queue in Supabase for flagged content
- Admin review screen in app

### 5. Expanded Test Suite
- Provider tests: ResidentProvider, WorldProvider, PostProvider, AuthService, ModerationService, AchievementProvider
- Widget tests: ChatMessageList, PostComposer, BentoGrid, CommentSheet
- Integration test: Auth flow (sign in → load worlds → post → sign out)

## Verification

After each batch:
```bash
flutter analyze --no-fatal-infos && flutter test && flutter build apk --debug
```
