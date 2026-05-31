# Local development — iOS & Android parity

Same Flutter app, same backend, same `pubspec.yaml` version. Use the commands below on either platform.

## One-time setup

```bash
cp .env.template .env          # Supabase URL + anon key
./scripts/firebase_beta_sync.sh # google-services.json + GoogleService-Info.plist
./scripts/check_beta_prereqs.sh
```

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
| Android (Play) | `./scripts/build_release_appbundle.sh` | `releases/*.aab` |
| Android (sideload) | `./scripts/build_release_apk.sh` | `releases/*.apk` |
| iOS (TestFlight) | `./scripts/build_release_ios.sh` | `releases/*.ipa` |

Bump `pubspec.yaml` build number (`+N`) for every build you ship. CI on `develop` still builds a signed **APK** only; iOS IPA is local until you add macOS runners or upload manually.

## Feature parity checklist

- Deep links: `vertiege://auth`, `verifier`, `invite` (Android intent-filters + iOS URL scheme)
- Push: Firebase + `flutter_local_notifications`
- Sign-in: Google + Apple (`sign_in_with_apple` on iOS)
- Campfire voice: LiveKit + `livekit-token` edge function (mic permission on both OSes)
- Subscriptions: `in_app_purchase` (Play + App Store products must exist in each console)

## TestFlight vs Play

- **Android closed testing**: upload AAB from `build_release_appbundle.sh`.
- **iOS TestFlight**: needs Apple **Distribution** certificate + App Store profile; see [IOS_XCODE_SETUP.md](IOS_XCODE_SETUP.md).
