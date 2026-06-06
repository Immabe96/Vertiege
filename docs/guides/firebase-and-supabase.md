# Firebase + Supabase Hybrid Setup

Vertiege uses Supabase as the source of truth for auth, app data, storage, RLS, realtime, and notification rows. Firebase is infrastructure-only: FCM, Crashlytics, Analytics, Remote Config, Performance SDK, and App Check.

## Completed In This Pass

- Firebase Android project detected: `veritage`.
- Firebase Android app detected: `1:92526224561:android:d523bec23fcecd1f7cae90`.
- Firebase packages are wired in Flutter.
- FCM background/opened/initial route handling is wired.
- Push tokens are stored in Supabase `public.device_tokens`.
- Supabase storage buckets are created/verified: `avatars`, `post-media`, `world-banners`, `world-icons`, `marketplace-media`, `chat-attachments`, `verification-proofs`.
- `verification-proofs` is private.
- `send-push` Edge Function is deployed with `verify_jwt = false` because it uses a custom `WEBHOOK_SECRET` bearer check for database webhooks.
- Release APK builds with:

```powershell
$env:JAVA_HOME="C:\Users\Immabe\AppData\Local\jdk-21.0.9+10"
$env:PATH="$env:JAVA_HOME\bin;$env:PATH"
flutter build apk --release --no-tree-shake-icons
```

## Required Supabase Secrets

`send-push` is deployed, but it will return `WEBHOOK_SECRET not set` until these secrets are configured:

```powershell
npx supabase secrets set WEBHOOK_SECRET="<strong-random-webhook-secret>" --project-ref wjaphoaxalvgjnrwqjwe
npx supabase secrets set SUPABASE_SERVICE_ROLE_KEY="<supabase-service-role-key>" --project-ref wjaphoaxalvgjnrwqjwe
npx supabase secrets set FIREBASE_SERVICE_ACCOUNT_JSON='<single-line-firebase-service-account-json>' --project-ref wjaphoaxalvgjnrwqjwe
```

Do not commit these values. Do not put them in Flutter `.env`.

## Supabase Notification Webhook

After setting secrets, create a Supabase Database Webhook:

- Table: `public.notifications`
- Event: `INSERT`
- Method: `POST`
- URL: `https://wjaphoaxalvgjnrwqjwe.supabase.co/functions/v1/send-push`
- Headers:

```text
Authorization: Bearer <WEBHOOK_SECRET>
Content-Type: application/json
```

The function reads `record.recipient_id`, fetches device tokens from `public.device_tokens`, and sends FCM HTTP v1 messages.

## Google Login

Use Supabase Auth as the identity owner.

In Google Cloud Console, configure the OAuth redirect URI:

```text
https://wjaphoaxalvgjnrwqjwe.supabase.co/auth/v1/callback
```

In Supabase Dashboard:

- Enable Auth Provider: Google.
- Add the Google client ID and secret.
- Add allowed redirect URL:

```text
vertiege://auth/callback
```

Do not add Firebase Auth unless auth ownership is intentionally changed.

## Firebase Console Checklist

- Cloud Messaging: enabled and test message can reach the Android app.
- Crashlytics: enabled; verify non-fatal errors arrive after a device run.
- Analytics: enabled; DebugView should show navigation and notification events.
- Remote Config: optional server defaults can mirror the app defaults.
- Performance Monitoring: Flutter SDK is active. Android Gradle auto-instrumentation is intentionally disabled because it crashes the local JDK/Gradle release build on this machine.
- App Check: configure Play Integrity/debug providers, but do not enable enforcement until debug and release APKs are verified.

## Flutter client (`.env`)

The mobile app reads **anon** credentials from a bundled `.env` asset (`pubspec.yaml` lists `.env`).

| Variable | Purpose |
|----------|---------|
| `SUPABASE_URL` | Project API URL |
| `SUPABASE_ANON_KEY` | Public anon JWT for client SDK |

Local: copy [`.env.template`](../../.env.template) → `.env`. CI/release APKs: GitHub Actions writes `.env` from `SUPABASE_URL` and `SUPABASE_ANON_KEY` secrets.

`main.dart` calls `SupabaseBootstrap.initialize()` before `runApp`. Auth screens call `SupabaseBootstrap.ensureReady()` before sign-in or sign-up. Missing keys → user-visible “not configured” message (not a crash).

Do **not** put service-role keys or Firebase service account JSON in `.env`.

## Build Notes

- `flutter build apk --release` with tree-shaken icons currently crashes the Windows Dart VM in this environment.
- Use `--no-tree-shake-icons` for reliable release builds.
- If the Dart VM crashes in `kernel_snapshot_program`, refresh the native pub cache:

```powershell
$objective = Join-Path $env:LOCALAPPDATA "Pub\Cache\hosted\pub.dev\objective_c-9.3.0"
if (Test-Path $objective) { Remove-Item -LiteralPath $objective -Recurse -Force }
$native = Join-Path $env:LOCALAPPDATA "Pub\Cache\hosted\pub.dev\native_toolchain_c-0.17.6"
if (Test-Path $native) { Remove-Item -LiteralPath $native -Recurse -Force }
flutter pub get
```
