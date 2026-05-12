# Vertiege — Project State

**Updated:** 2026-05-12 (UI/UX polish pass active)

## Vision

Vertiege is a semi-social, semi-gamified gateway to a **Realm** of **Worlds**. Residents (users) are distinguished by real-world achievements, earn prestige, and level up. Three world types: Wealth (paid), Profession (proof-based), Custom/Dominion (user-created, gated by resident level). Governance via Council + Sovereign with inactivity ejection. Discord-style channels + Twitter-style feeds per world, aggregated into the Realm Feed (Nexus).

Full vision: `.claude/../memory/vertiege-vision.md`

## Current: Phase 3 - UI/UX Polish

### Completed in Phase 3 (2026-05-12)
- Rebuilt World Discover with image-led world cards, visual rails, search, and consistent generated world artwork.
- Rebuilt Chat tab so DMs are separate from joined-world channel navigation.
- Replaced remaining generated placeholder artwork sets: world banners, avatars, badges, achievement medallions, profession medallions, tier emblems, empty states, splash/onboarding backgrounds, and app icon assets.
- Replaced inconsistent full-screen/section spinners in ascension, hall, subscriptions, world invites, and access verification with glass loading states.
- Added branded error state handling for resident profile failures and tightened mounted checks after async image/profile loads.
- Removed visible placeholder-style event date copy (`TBD`) from event cards.

### UI/UX QA Gate
- Device smoke test on the next release build for real scrolling, tap targets, and tab flow.
- Small inline activity indicators remain only where they are direct button/progress feedback.
- Feature work should resume after this QA pass stays stable on-device.

## Completed: Phase 2 - 9/9 gaps closed

### Completed in Phase 1 (Build & Sign)
- Release keystore (`android/upload-keystore.jks`, RSA 2048)
- Release signing in build.gradle.kts
- Env vars: flutter_dotenv, .env with live Supabase creds
- R8 ProGuard rules fixed
- INTERNET permission added to manifest
- Signed APK builds: `flutter build apk --release` → 139MB
- Keystore backup doc: `docs/superpowers/specs/keystore-backup.md`

### Phase 2 fixes applied (2026-05-04, pre-vision sync)
- Permissions: CAMERA, READ_MEDIA_IMAGES, READ_EXTERNAL_STORAGE (Android) + NSCameraUsageDescription, NSPhotoLibraryUsageDescription (iOS)
- Onboarding: premade avatars replaced with Camera/Gallery photo upload (image_picker)
- Onboarding: profession dropdown replaced with ChoiceChips
- Onboarding: gold background removed, clean dark gradient instead
- Onboarding: "Self-declared — verification coming in a future update" note
- Identity screen: same avatar upload + chip selector applied to edit profile
- CosmeticAvatar: now handles FileImage, NetworkImage, and AssetImage via _resolveImage helper

### What already exists (vision-aligned)
- 12 Supabase tables: profiles, worlds, world_members, channels, posts, events, reports, invites, dm_rooms, chat_messages, channel_messages, notifications, moderation_logs
- 3 world types (wealth/profession/dominion), 15 hardcoded worlds
- NexusScreen (Realm Feed) with All/Following/Announcements + sort
- World detail with feed, channels (Supabase Realtime), events, members
- 67 achievements across 11 categories, XP/tier system (5 tiers)
- Custom world creation gated by resident tier
- Council standing in schema (rep 5000), sovereign_id on worlds
- Moderation service + logs (mute/ban)
- 40+ widget components, 20 screens, 10 Riverpod providers

### Completed gaps (2026-05-04)
- **Gap 1: Council automation** — `CouncilService` handles 15-day inactivity ejection, sovereign voting with random tiebreaker. Checks run on world detail load. Ejected members drop to rep 4999; seats backfill from next highest rep.
- **Gap 2: Dynamic prestige** — `PrestigeService` calls `calculatePrestige` with real metrics. Prestige recalculates on post creation and member join/leave. Results persist to Supabase and local state.
- **Gap 5: World leveling** — `activityScore` field on `World` tracks dominion world progression. 10 levels with thresholds (0 → 10k). Posts (+3), member joins (+10) increment score. Resident capacity gated by world level (20 at L1 → 2500 at L10). Premade worlds are max level (10), unlimited capacity. `worldLevelFor()` and `residentCapacityFor()` on WorldNotifier.
- **Gap 6: WorldFeatures enforcement (partial)** — Events card on WorldDetailScreen gated behind `features.events`. `featuresForWorld()` available on WorldNotifier for gating additional UI.

### New files
- `lib/services/council_service.dart` — inactivity detection, ejection, sovereign election with random tiebreaker
- `lib/services/prestige_service.dart` — dynamic prestige calculation from real activity metrics

### Modified files
- `lib/config/tiers.dart` — added `worldLevelThresholds`, `worldLevelCapacity`, `getWorldLevel`, `getResidentCapacity`
- `lib/models/world.dart` — added `activityScore` to `WorldBase`, updated `copyWith`/`toJson`/`fromJson`/`fromSupabase`
- `lib/state/world_provider.dart` — added `updateWorldPrestige`, `featuresForWorld`, `runCouncilCheck`, `addActivityScore`, `worldLevelFor`, `residentCapacityFor`
- `lib/state/post_provider.dart` — triggers prestige recalc + activityScore on post creation
- `lib/state/resident_provider.dart` — triggers prestige recalc + activityScore on world join/leave, capacity-gated joinWorld for dominion worlds
- `lib/screens/world_detail_screen.dart` — runs council check on load, gates events behind feature flags

### Completed gaps (continued)
- **Gap 7: WorldConstitution enforcement** — constitution field on World model. `posting: council-only` gates post creation. `commenting: council-only` gates commenting. `canPost`/`canComment` on WorldPermissions respect constitution. Constitution editable per-world.
- **Gap 8: Report flow UI** — Report button already existed on PostItem. Now wired: `submitReport` on ModerationService persists to Supabase `reports` table with reason + details. `getReports` provides data for moderation dashboard.
- **Gap 9: Leaderboard** — WorldLeaderboard refactored to fetch real rep data from Supabase. Added to WorldDetailScreen below channels. Shows top 10 residents by rep with rank badges (gold/silver/bronze).

### Modified files (continued)
- `lib/models/world.dart` — added `constitution` field to World
- `lib/services/permission_service.dart` — `canPost`/`canComment` now respect constitution posting/commenting rules
- `lib/services/moderation_service.dart` — added `submitReport` and `getReports`
- `lib/widgets/feed/post_item.dart` — wired report button to ModerationService.submitReport
- `lib/widgets/worlds/leaderboard.dart` — refactored to fetch and display real member rep data
- `lib/state/post_provider.dart` — constitution-aware permission checks

### Completed gaps (continued)
- **Gap 6: WorldFeatures enforcement** — events, lounge, and governance wired. Events card gated on prestige 15. Lounge channel hidden until prestige 10. Settings/manage access requires governance (prestige 50). Remaining flags (vault, audioRooms, marketplace, treasury, alliances, landmarks) have no existing UI and will gate features when built.
- `lib/widgets/worlds/world_channel_list.dart` — filters lounge channel by features.lounge
- `lib/screens/world_detail_screen.dart` — settings button gated on features.governance

### Completed gaps (continued)
- **Gap 3: Proof verification pipeline** — `VerificationService` uploads proof documents to Supabase Storage. `WorldAccessGuard` now shows a proof upload dialog (image picker → upload → pending review). `VerificationReviewScreen` at `/admin/verifications` for admin approve/reject. `verifyProfession` accepts optional proof path. Auto-verification fallback for self-declared professions.
- `lib/services/verification_service.dart` — upload proof, submit verification, get pending, approve/reject
- `lib/screens/verification_review_screen.dart` — admin review queue with approve/reject
- `lib/widgets/worlds/world_access_guard.dart` — proof upload dialog with image picker
- `lib/state/resident_provider.dart` — `verifyProfession` now accepts proofPath, uses real upload + submission
- `lib/router/app_router.dart` — added `/admin/verifications` route
- `lib/screens/settings_screen.dart` — added "Verification Review" link in Moderation section

### Completed gaps (continued)
- **Gap 4: Payments** — `StoreService` wraps in_app_purchase with release-mode gate (`isEnabled => false`). Wealth world purchase flow in `WorldAccessGuard` with tiered pricing ($4.99–$49.99). Pay-to-boost for dominion worlds in world settings: +50 activityScore per boost, 3 boosts/month cap, $4.99 per boost. Boost tracking via `boostCount`/`lastBoostMonth` on World model. All IAP logic gated behind `StoreService.isEnabled` — safe to ship in dev mode.
- `lib/services/store_service.dart` — IAP wrapper with `buyWealthTier`, `buyWorldBoost`, `restorePurchases`, fallback products
- `lib/models/world.dart` — added `boostCount`, `lastBoostMonth`, `boostsRemaining`, `boostActivityPoints`, `maxBoostsPerMonth`
- `lib/state/world_provider.dart` — added `boostWorld` method with purchase → activityScore increment + monthly cap enforcement
- `lib/screens/world_settings_screen.dart` — added `_BoostWorldCard` with level progress, boost button, remaining count
- `lib/widgets/worlds/world_access_guard.dart` — purchase sheet for wealth tier buy-in

### Remaining gaps

**None.** All 9 gaps are closed. Phase 2 is complete.

### Known pre-existing issues
- Several screens use NetworkImage directly (not CosmeticAvatar) — will break with local file paths
- No push notification setup (in-app only)
- AuthCallbackScreen is a placeholder (no deep-link handling)

## Build commands
```bash
flutter build apk --release
adb install -r build\app\outputs\flutter-apk\app-release.apk
```

## Supabase
- URL: https://wjaphoaxalvgjnrwqjwe.supabase.co
- Key in .env (gitignored)

## Upcoming Phases

| Phase | Goal |
|-------|------|
| 2 — Gap Closure | Close the 9 gaps above, starting with council automation + dynamic prestige |
| 3 — Polish | UI fit & finish, dead deps, font flash, loading states, scroll jank, branding |
| 4 — Ship | Payments, Sentry crash reporting, push notifications, final APK, beta distribution |
