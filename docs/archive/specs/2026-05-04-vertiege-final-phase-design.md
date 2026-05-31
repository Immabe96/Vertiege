# Vertiege Final Phase — Design Spec

**Date:** 2026-05-04
**Status:** Approved
**Approach:** Sequential (A)

## Goal

Push Vertiege from nearly-complete to beta-ready through four sequential phases: Build & Sign, Bug Hunt & Fix, Polish & Performance, Ship.

## Context

- Flutter app (Riverpod + Supabase + go_router), Material 3
- Platforms: Android first, iOS next (private beta, not Play Store / App Store)
- 5–20 trusted beta testers, Supabase backend already live
- Android release config is broken (signed with debug keys)
- No crash reporting, silent error swallowing, dead dependencies
- ~27 unit tests, no provider/widget/integration tests

## Phase 1 — Build & Sign (target: ~2 days)

**Goal:** Produce a signed release APK that can be distributed to beta testers.

1. Generate Android release keystore (`upload-keystore.jks`)
2. Create `android/key.properties` with keystore credentials
3. Update `android/app/build.gradle.kts` to use release signing config
4. Switch env var management from compile-time `String.fromEnvironment` to `flutter_dotenv`
5. Add `.env.template` for team reference, ensure `.env` in `.gitignore`
6. Build signed release APK, test on a physical device
7. Prepare iOS signing skeleton: confirm bundle ID, create placeholder `Release.xcconfig`

**Exit criteria:** Installable APK on a real Android device, signed with release keys.

## Phase 2 — Bug Hunt & Fix (target: ~4–5 days)

**Goal:** Systematic sweep of every screen and interaction — find and fix bugs before beta.

### Auth & Onboarding
- Fix race condition in `AuthService`: token storage fire-and-forget pattern
- Test sign-up, login, onboarding flow, auth redirect logic
- Password reset if implemented

### World Browsing & Feed
- World discovery, tier-gated entry, join/leave
- Post creation, reactions, comments
- Loading states, empty states, pagination

### Chat & Real-time
- Realtime message delivery, connection drops
- DM rooms, channel messages
- Message ordering, duplicates

### Invites
- Code generation, redemption, edge cases (expired, used, invalid)
- Tier-restricted invite flows

### Settings, Profile, Achievements, Notifications
- Full sweep of remaining screens
- Data persistence across sessions
- Notification delivery and tap-to-navigate

### Process
- Each bug gets severity label (crash / data-loss / cosmetic)
- One commit per fix
- Crash-level and data-loss bugs fixed immediately; cosmetic queued to Phase 3

**Exit criteria:** No crash-level or data-loss bugs. All screens functional.

## Phase 3 — Polish & Performance (target: ~3–4 days)

**Goal:** App feels production-quality, not prototype.

1. **Dead dependency cleanup:** Remove unused `riverpod_annotation`, `riverpod_generator`, `json_annotation`, `json_serializable`, `build_runner`, `flutter_animate` (if confirmed unused)
2. **Font flash fix:** Bundle fonts as assets instead of runtime-only Google Fonts loading
3. **Loading/empty/error states:** Audit every screen for consistency — shimmer on load, informative empty states, actionable error states
4. **Scroll performance:** Profile and fix jank in feed lists, chat, world browser
5. **Offline behavior:** Test connectivity loss/recovery flows, validate `OfflineBanner` and retry logic
6. **App metadata:** App name, launcher icon, splash screen consistent with branding
7. **Web metadata:** Update `web/index.html` title/description, `manifest.json` PWA name/icons (quick win)

**Exit criteria:** No visible jank, consistent UI states across all screens, branded app identity.

## Phase 4 — Ship (target: ~1 day)

**Goal:** Distribute to beta testers with monitoring in place.

1. **Crash reporting:** Integrate Sentry (free tier sufficient for beta). Add `FlutterError.onError` and `PlatformDispatcher.instance.onError` handlers. Replace silent `catch (_) {}` blocks with `logger.e()` + `Sentry.captureException()` in critical paths.
2. **Logging:** Wire up `logger` package for structured debug logging (already declared in pubspec)
3. **Final build:** Signed release APK + optional AAB
4. **Distribution:** Direct download or Firebase App Distribution for the beta group
5. **One-page beta guide:** What to test, how to report issues, known limitations

**Exit criteria:** APK delivered to testers, Sentry receiving events, feedback channel established.

## Risks & Mitigations

| Risk | Mitigation |
|------|-----------|
| Env var migration breaks existing configs | `.env.template` makes required vars explicit; validate at startup |
| Release keystore lost | Document backup procedure; store keystore securely |
| Crash reporting adds noise | Only wire critical paths; configure Sentry sampling for beta |
| iOS signing deferred too long | At minimum confirm bundle ID + create config skeleton in Phase 1 |
