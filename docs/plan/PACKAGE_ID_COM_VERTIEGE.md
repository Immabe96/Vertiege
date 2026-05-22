# Package ID: `com.vertiege`

Android `applicationId` and iOS/macOS bundle identifier are **`com.vertiege`**.

## Google OAuth (Android client form)

| Field | Value |
|-------|--------|
| Package name | `com.vertiege` |
| SHA-1 | From `cd android; .\gradlew signingReport` (debug variant) |

## Supabase Auth redirects (unchanged)

- Mobile: `vertiege://auth/callback`
- Supabase callback: `https://wjaphoaxalvgjnrwqjwe.supabase.co/auth/v1/callback`

## Firebase (required after package change)

The repo’s `google-services.json` may list `com.vertiege` but Firebase must have a matching **Android app** registered, or FCM/Crashlytics will not initialize correctly.

1. Firebase Console → project **veritage** → Add Android app → `com.vertiege`
2. Replace `android/app/google-services.json` with the downloaded file
3. Re-run `flutterfire configure` if you use FlutterFire CLI

## Install note

Changing `applicationId` creates a **new** app on the device. Uninstall the old package if present:

```powershell
adb uninstall com.imma96.virtual_status_worlds
```

New installs use:

```powershell
adb uninstall com.vertiege
```
