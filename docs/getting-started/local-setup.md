# Local development — iOS & Android parity

Same Flutter app, same backend, same `pubspec.yaml` version. Use the commands below on either platform.

## One-time setup

```bash
cp .env.template .env          # SUPABASE_URL + SUPABASE_ANON_KEY (required for sign-up)
./scripts/firebase_beta_sync.sh # google-services.json + GoogleService-Info.plist
./scripts/check_beta_prereqs.sh
```

Supabase initializes at app launch (`main.dart` → `SupabaseBootstrap.initialize()`). Without a valid `.env`, sign-up shows a clear configuration error instead of a silent failure.

| Step | Android | iOS (Mac) |
|------|---------|-----------|
| Store keys | `android/key.properties` + `upload-keystore.jks` | `ios/Flutter/Release.xcconfig` → `DEVELOPMENT_TEAM` |
| Native deps | Gradle (automatic) | `cd ios && pod install` after `flutter pub get` |
| Voice (Campfire) | `RECORD_AUDIO` in manifest | `NSMicrophoneUsageDescription` in Info.plist |
| WebRTC | `packaging.jniLibs.pickFirst` in `build.gradle.kts` | Static CocoaPods + **Embed WebRTC Framework** build phase |

## Daily dev

```bash
flutter pub get
./scripts/run_dev.sh          # auto-picks device
./scripts/run_dev.sh ios      # simulator
./scripts/run_dev.sh android  # emulator
```

iOS simulator needs the WebRTC embed phase (added by `pod install` from `ios/Podfile`). If Campfire crashes with `dyld: WebRTC.framework`, run:

```bash
cd ios && pod install && cd ..
flutter clean && flutter pub get
flutter build ios --simulator
```

## Release builds (beta)

| Platform | Script | Output |
|----------|--------|--------|
| **Both stores** | `./scripts/build_release_all.sh` | `releases/*.aab` + `releases/*.ipa` (one `+N` bump) |
| Android (Play) | `./scripts/build_release_appbundle.sh` | `releases/*.aab` |
| Android (sideload) | `./scripts/build_release_apk.sh` | `releases/*.apk` |
| iOS (TestFlight) | `./scripts/build_release_ios.sh` | `releases/*.ipa` |

Bump `pubspec.yaml` build number (`+N`) for every build you ship. Use **`build_release_all.sh`** so Play and TestFlight get the same build number.

CI on `develop`: Ubuntu builds signed **APK**; macOS job builds **iOS simulator** (compile-only, no IPA).

## UI / UX standards

See [../reference/design-system.md](../reference/design-system.md) and [../reference/DESIGN.md](../reference/DESIGN.md) (Commune tokens). Design tokens and navigation are shared — do not fork per platform.

## Device smoke matrix (before beta)

| Check | Android emulator | iOS simulator |
|-------|------------------|---------------|
| Login (Google) | ✓ | ✓ |
| Login (Apple) | n/a | ✓ |
| Nexus feed loads | ✓ | ✓ |
| Join Campfire + mic prompt | ✓ | ✓ |
| Settings shows version + OS | ✓ | ✓ |

## Feature parity checklist

- Deep links: `vertiege://auth`, `verifier`, `invite` (Android intent-filters + iOS URL scheme)
- Push: Firebase + `flutter_local_notifications`
- Sign-in: Google + Apple (`sign_in_with_apple` on iOS)
- Campfire voice: LiveKit + `livekit-token` edge function (mic permission on both OSes)
- Subscriptions: `in_app_purchase` (Play + App Store products must exist in each console)

## TestFlight vs Play

- **Android closed testing**: upload AAB from `build_release_appbundle.sh`.
- **iOS TestFlight**: needs Apple **Distribution** certificate + App Store profile; see [IOS_XCODE_SETUP.md](IOS_XCODE_SETUP.md).
