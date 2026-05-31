# Closed beta setup (Android + iOS)

Operator guide for shipping **Vertiege** to a small trusted group (~5–20 testers).  
Package / bundle ID: **`com.vertiege`** · Supabase project: **`wjaphoaxalvgjnrwqjwe`**

---

## Overview

| Platform | Recommended channel | Build artifact |
|----------|---------------------|----------------|
| **Android** | Google Play **Closed testing** (best) or direct APK | `.aab` (Play) or `.apk` (sideload / Firebase) |
| **iOS** | **TestFlight** (Internal → External) | `.ipa` via Xcode or `flutter build ipa` |

Testers get the **same backend** (production Supabase). Bump **`pubspec.yaml` build number (`+N`)** for every build you distribute.

---

## 0. One-time prerequisites

### Accounts & legal

- [ ] **Google Play Console** — developer account ($25 one-time)
- [ ] **Apple Developer Program** — enrolled ($99/year) — required for TestFlight
- [ ] **Privacy policy URL** (hosted, public) — required by Play & App Store Connect
- [ ] **Support contact email** for store listings and tester comms

### Backend (Supabase) — already live

- [ ] Migrations applied: `supabase db push` (project linked)
- [ ] Auth providers you need: **Email**, **Google** (and **Apple** on iOS if you enable it)
- [ ] Redirect URLs in Supabase → Authentication → URL configuration:
  - `vertiege://auth/callback`
  - Site URL can stay your Supabase URL for now
- [ ] Optional: cap signups in Dashboard if you want invite-only growth later
- [ ] Push: `send-push` secrets + DB webhook — see [FIREBASE_SUPABASE_HYBRID_SETUP.md](FIREBASE_SUPABASE_HYBRID_SETUP.md)

### Staff / verifiers

Grant in Supabase Dashboard → Authentication → user → **App metadata**:

```json
{ "is_verifier": true, "role": "verifier" }
```

Testers use the normal app; staff open **Settings → Staff review**. See [VERIFIER_PORTAL.md](VERIFIER_PORTAL.md).

### Firebase (CLI sync)

Installed on this machine via Homebrew (`firebase-cli`). **One-time login** (browser):

```bash
firebase login
cd /path/to/Vertiege
./scripts/firebase_beta_sync.sh
```

That script:

- Lists Android / iOS / Web apps in project **`veritage`**
- Downloads `android/app/google-services.json`
- Downloads `ios/Runner/GoogleService-Info.plist`
- Runs `flutterfire configure` for `lib/firebase_options.dart`

Project default is set in [`.firebaserc`](../.firebaserc). Override with `FIREBASE_PROJECT=other`.

The app already initializes Firebase from **`lib/firebase_options.dart`**; the plist/json files are still recommended for native Google Sign-In and tooling.

### Local sanity check

```bash
./scripts/check_beta_prereqs.sh
```

Day-to-day dev on **both** platforms: [docs/beta/LOCAL_DEV.md](beta/LOCAL_DEV.md). UI rules: [UI_STANDARDS.md](UI_STANDARDS.md).

### Versioning (both stores)

- Single source: **`pubspec.yaml`** `version: 1.x.y-beta.z+N`
- Run `./scripts/sync_app_version.sh` after every version change (release scripts do this automatically).
- Ship the **same `+N`** to Play and TestFlight: `./scripts/build_release_all.sh`
- Firebase Remote Config:
  - `minimum_build` — global floor for both platforms
  - `minimum_build_android` / `minimum_build_ios` — optional overrides if review cadence diverges

---

## 1. Environment & CI secrets

### Local `.env` (bundled into release builds)

Copy [`.env.template`](../.env.template) → `.env`:

```bash
SUPABASE_URL=https://wjaphoaxalvgjnrwqjwe.supabase.co
SUPABASE_ANON_KEY=<your-anon-key>
VERIFIER_ADMIN_EMAILS=you@example.com   # optional debug fallback
```

Never commit `.env`. The anon key is public in the client; security is **RLS**, not hiding the key.

### GitHub Actions (Android CI APK)

Repository → **Settings → Secrets and variables → Actions**:

| Secret | Purpose |
|--------|---------|
| `SUPABASE_URL` | Embedded in CI `.env` for release APK |
| `SUPABASE_ANON_KEY` | Same |
| `ANDROID_KEYSTORE_BASE64` | `base64` of `android/upload-keystore.jks` |
| `ANDROID_KEYSTORE_PASSWORD` | Keystore password |
| `ANDROID_KEY_PASSWORD` | Key password |
| `ANDROID_KEY_ALIAS` | `upload` (optional) |

Generate signing locally once:

```bash
./scripts/setup-android-signing.sh
```

Back up the keystore — see [superpowers/specs/keystore-backup.md](superpowers/specs/keystore-backup.md).

---

## 2. Android closed beta

### Option A — Google Play Closed testing (recommended)

Best install experience (updates, no “unknown sources”).

1. **Create the app** in [Play Console](https://play.google.com/console) → Create app → package `com.vertiege`.
2. Complete **Dashboard** checklist (store listing draft, content rating questionnaire, target audience, data safety form).
3. **App signing**: use Play App Signing (default). Upload your **upload key** (same `upload-keystore.jks`).
4. Build an App Bundle:

   ```bash
   ./scripts/build_release_appbundle.sh
   ```

   Output: `build/app/outputs/bundle/release/app-release.aab`  
   Copy to `releases/` if you version manifests there.

5. **Release → Testing → Closed testing** → Create track → Upload `.aab`.
6. **Testers** → Create email list → add addresses → share opt-in link from Play Console.
7. For each new build: bump `+N` in `pubspec.yaml`, rebuild AAB, upload to the same track.

**Google Sign-In on Play builds:** register **release** SHA-1 in Firebase + Google Cloud OAuth Android client. Get fingerprint:

```bash
keytool -list -v -keystore android/upload-keystore.jks -alias upload
```

Add that SHA-1 to Firebase Android app `com.vertiege` and Google Cloud credentials.

### Option B — Direct APK (fastest first cohort)

1. CI: push to `develop` → download artifact `vertiege-apk-*` or use [GitHub Releases](https://github.com/Immabe96/Vertiege/releases).
2. Local:

   ```bash
   ./scripts/build_release_apk.sh
   ```

3. Share `releases/vertiege-*-arm64-release.apk` (Drive, email, etc.).
4. Testers: enable **Install unknown apps** for the browser/files app, install APK.

### Option C — Firebase App Distribution (optional)

1. Firebase Console → **App Distribution** → enable.
2. Upload the same release APK; add tester emails.
3. Good middle ground before Play closed track is ready.

---

## 3. iOS closed beta (TestFlight)

### 3.1 Apple & Firebase one-time

1. [Apple Developer](https://developer.apple.com) → Certificates, Identifiers & Profiles:
   - **App ID** `com.vertiege` (enable Push Notifications, Sign in with Apple if used).
   - **Distribution** certificate + **App Store** provisioning profile for `com.vertiege`.
2. [App Store Connect](https://appstoreconnect.apple.com) → **My Apps** → **+** → iOS app, bundle ID `com.vertiege`.
3. Firebase Console → add **iOS app** `com.vertiege` → download **`GoogleService-Info.plist`** → place at:

   ```
   ios/Runner/GoogleService-Info.plist
   ```

   Template: [ios/Runner/GoogleService-Info.plist.example](../ios/Runner/GoogleService-Info.plist.example).  
   Do not commit the real plist to a public repo — keep a secure backup.

4. Run:

   ```bash
   cd ios && pod install && cd ..
   ```

5. **Google Sign-In (iOS):** Google Cloud → OAuth **iOS** client with bundle ID `com.vertiege`. Add reversed client ID to URL schemes if Google’s plist flow requires it (in addition to `vertiege` for Supabase OAuth).

6. **Supabase:** ensure redirect `vertiege://auth/callback` is allowed (same as Android).

`Info.plist` includes the **`vertiege`** URL scheme for OAuth deep links.

### 3.2 Build & upload to TestFlight

On a **Mac** with Xcode installed:

```bash
cp .env.template .env   # fill Supabase keys
flutter pub get
cd ios && pod install && cd ..

# Archive + IPA (needs signing configured in Xcode first)
open ios/Runner.xcworkspace
```

In Xcode:

1. Select **Runner** target → **Signing & Capabilities** → Team = your Apple team, bundle `com.vertiege`.
2. Product → **Archive** → **Distribute App** → **App Store Connect** → Upload.

Or CLI (after export options exist):

```bash
flutter build ipa --release
# Upload with Transporter app or: xcrun altool --upload-app ...
```

### 3.3 TestFlight testers

1. App Store Connect → your app → **TestFlight**.
2. **Internal testing** — up to 100 users on your App Store Connect team (instant, no review).
3. **External testing** — add emails / public link; first build needs **Beta App Review** (usually 24–48h).
4. Fill **Test Information** (what to test, contact email, privacy policy URL).
5. Each upload: bump `pubspec` build `+N`, new archive, submit to TestFlight.

Testers install **TestFlight** from the App Store, accept invite, install Vertiege.

---

## 4. Release checklist (every beta drop)

```bash
# 1. Version
#    Edit pubspec.yaml — bump +N (and beta name if needed: 1.1.0-beta.3+7)
./scripts/sync_app_version.sh

# 2. Quality gate
flutter test
./scripts/check_beta_prereqs.sh

# 3. Build
./scripts/build_release_appbundle.sh    # Play
./scripts/build_release_apk.sh --no-bump   # APK / GitHub (if CI not used)

# 4. iOS (Mac)
flutter build ipa --release

# 5. Ship
#    - Upload AAB → Play closed track
#    - Upload IPA → TestFlight
#    - Post release notes in beta/TESTER_GUIDE.md or Discord/email

# 6. Tag (optional)
git tag beta-1.1.0-beta.3+7 && git push origin beta-1.1.0-beta.3+7
```

Commit `releases/manifest-*.json` when you track local APK manifests.

---

## 5. Tester comms

Share [beta/TESTER_GUIDE.md](beta/TESTER_GUIDE.md) with:

- Install link (Play opt-in / TestFlight / APK instructions)
- Login: email or Google
- How to report bugs (one channel you monitor)
- Known limitations (IAP stubs, etc.)

---

## 6. Monitoring during beta

| Signal | Where |
|--------|--------|
| Crashes | Firebase **Crashlytics** |
| Usage | Firebase **Analytics** |
| Auth / DB errors | Supabase **Logs** |
| Push delivery | Supabase `device_tokens` + `send-push` function logs |

---

## 7. Quick links

| Doc | Topic |
|-----|--------|
| [DEVELOPMENT_WORKFLOW.md](DEVELOPMENT_WORKFLOW.md) | CI / develop → APK |
| [releases/README.md](../releases/README.md) | APK naming & scripts |
| [FIREBASE_SUPABASE_HYBRID_SETUP.md](FIREBASE_SUPABASE_HYBRID_SETUP.md) | Push, webhooks |
| [DEVICE_UAT.md](DEVICE_UAT.md) | Device test scenarios |
| [VERIFIER_PORTAL.md](VERIFIER_PORTAL.md) | Staff review |
| [plan/PACKAGE_ID_COM_VERTIEGE.md](plan/PACKAGE_ID_COM_VERTIEGE.md) | OAuth SHA-1 |

---

## Current repo gaps (iOS)

Before first TestFlight upload, confirm on your Mac:

- [ ] `ios/Runner/GoogleService-Info.plist` present (Firebase iOS app)
- [ ] Xcode signing team selected
- [ ] Push capability + APNs key in Apple Developer (for FCM on iOS)
- [ ] **Sign in with Apple** capability if you ship Apple login on iOS

Android Firebase (`android/app/google-services.json`) is already in the repo for `com.vertiege`.
