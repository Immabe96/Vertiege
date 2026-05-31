# Audit fix tracker — F01–F36

Source: [2026-05-24-cursor-swarm-audit.md](./2026-05-24-cursor-swarm-audit.md)

| ID | Sev | Status | Notes |
|----|-----|--------|-------|
| F01 | High | **done** | Sign-out clears outbox + session caches |
| F02 | High | **done** | Client-safe profile upsert + `20260524150000_profiles_privilege_guard.sql` |
| F03 | High | **done** | `chat_service_test` — `sortedParticipantIds` |
| F04 | High | **partial** | `deep_link_redirects_test`; full GoRouter matrix still optional |
| F05 | High | **done** | Duplicate connectivity listener removed |
| F06 | Med | **done** | Admin email allowlists only in `kDebugMode` |
| F07 | Med | **doc** | App Check boundary documented in audit; RLS is boundary |
| F08 | Med | **done** | `debug_logs` insert only in `kDebugMode` (push service) |
| F09 | Med | **done** | `verifyProfession` requires proof path for server submit |
| F10 | Med | **done** | `WorldService.createWorld` uses `create_world_full` RPC |
| F11 | Med | **done** | Server-authoritative `joinedWorldIds` |
| F12 | Med | **done** | Settings → discard failed outbox items |
| F13 | Med | **done** | OAuth → `/onboarding` when gate incomplete |
| F14 | Med | **done** | Gate prefs synced from profile; removed `main` gate preload |
| F15 | Med | **done** | Splash waits for resident load (≤6s) when session exists |
| F16 | Med | **done** | Push routes queued until post-splash |
| F17 | Med | **done** | `redirectMissingChannelId` |
| F18 | Med | **done** | Table tests for all reserved world segments |
| F19 | Med | **done** | `firebase_bootstrap_test` (state accessors) |
| F20 | Med | **done** | Streak/gamification unit tests + `resident_provider` sign-out test |
| F21 | Med | **done** | Channel/teaser explore path tests (`?id=` query) |
| F22 | Med | **done** | `OfflineBanner.onRetry` + copy |
| F23 | Med | **done** | Supabase failure `MaterialBanner` + retry |
| F24 | Med | **done** | Gradle profile comment in `gradle.properties` |
| F25 | Med | **done** | Release minify/shrink enabled + expanded ProGuard rules |
| F26 | Med | **done** | Linux/Firebase note in linux-setup doc |
| F27 | Low | **done** | Auth tokens no longer mirrored; legacy keys cleared on sign-out |
| F28 | Low | **partial** | Signup min 8 chars; enable leaked-password in Supabase dashboard |
| F29 | Low | **done** | `FeatureFlags.postOutboxEnabled` gates `_runOrQueue` |
| F30 | Low | **done** | `minimum_build` + `maintenance_banner` in `app.dart` |
| F31 | Low | **done** | `record_daily_check_in` RPC + server gamification reconcile |
| F32 | Low | **done** | Removed benchmark placeholder test |
| F33 | Low | **done** | Deleted unused `safe_async_builder.dart` |
| F34 | Low | **done** | Dev Firebase status in Settings (debug only) |
| F35 | Low | **done** | CI Java 17 aligned with app |
| F36 | Low | **done** | Channel load keeps error distinct from empty list |

## Deploy / verify (manual)

| Step | Status |
|------|--------|
| `flutter test` / `flutter analyze` | **done** (129 tests, 2026-05-24) |
| `supabase db push` for pending local migrations | **done** (2026-05-24) |
| Device UAT (`docs/DEVICE_UAT.md`) | pending |
| ANR confirmation on CPH2649 | pending |
| Supabase Auth: enable leaked-password protection | **deferred** |
