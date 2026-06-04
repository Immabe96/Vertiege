# Firebase App Check (Wave 21)

The Flutter app activates App Check in `AppCheckService` (debug providers in debug builds; Play Integrity / App Attest in release).

## Client

- `lib/services/supabase_app_check.dart` exposes `SupabaseAppCheck.headers()` for optional `X-Firebase-AppCheck` on sensitive calls.
- Wire headers into custom edge clients when verifying purchases or admin actions.

## Server / edge

1. Enable App Check in the Firebase console for iOS and Android apps.
2. On Supabase Edge Functions, validate the App Check token before running store verify or other privileged handlers.
3. Register debug tokens for local development (Firebase console → App Check → Manage debug tokens).

Production enforcement should be rolled out on **staging** first; keep a bypass flag for internal QA builds if needed.
