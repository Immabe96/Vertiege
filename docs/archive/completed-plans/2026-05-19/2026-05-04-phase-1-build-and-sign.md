# Phase 1 — Build & Sign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Produce a signed release APK that beta testers can install on their Android devices.

**Architecture:** Generate a Java Keystore for release signing, wire it into the Android Gradle build, migrate environment variables from compile-time Dart constants to `flutter_dotenv` (improving portability across CI and team members), and prepare an iOS signing skeleton for the next phase.

**Tech Stack:** Flutter 3.x, Kotlin DSL Gradle (Android), flutter_dotenv, Java keytool

---

### Task 1: Generate Android release keystore

**Files:**
- Create: `android/upload-keystore.jks` (via keytool, never committed)

- [ ] **Step 1: Generate the keystore with keytool**

```bash
keytool -genkey -v \
  -keystore android/upload-keystore.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias upload
```

You will be prompted for:
- Keystore password (create a strong one, save it)
- Name/org/city — use your actual details or "Vertiege" for org
- Key password — same as keystore password (press Enter to use same)

- [ ] **Step 2: Verify the keystore was created**

```bash
keytool -list -v -keystore android/upload-keystore.jks -alias upload
```

Expected: Certificate fingerprint and validity info displayed. Confirm 10000 days validity.

- [ ] **Step 3: Verify keystore is in .gitignore**

The `.gitignore` already ignores most build artifacts. Confirm the keystore entry is present:

```bash
grep -n "upload-keystore" .gitignore || echo "Not in gitignore"
```

If not present, we'll add it in Task 2 alongside `key.properties`.

---

### Task 2: Create key.properties

**Files:**
- Create: `android/key.properties` (never committed, contains secrets)

- [ ] **Step 1: Create key.properties**

Write `android/key.properties`:

```
storePassword=<your-keystore-password>
keyPassword=<your-key-password>
keyAlias=upload
storeFile=../upload-keystore.jks
```

Replace `<your-keystore-password>` and `<your-key-password>` with the passwords from Task 1. The `storeFile` path is relative to `android/app/`.

- [ ] **Step 2: Add keystore and key.properties to .gitignore**

Add these lines to `.gitignore`:

```
# Android release signing
/android/upload-keystore.jks
/android/key.properties
```

- [ ] **Step 3: Verify .gitignore is effective**

```bash
git check-ignore android/upload-keystore.jks android/key.properties
```

Expected: Both paths are listed (they are ignored). If one fails, re-check your `.gitignore` entries.

---

### Task 3: Update build.gradle.kts for release signing

**Files:**
- Modify: `android/app/build.gradle.kts`

- [ ] **Step 1: Read the keystore properties at the top of build.gradle.kts**

Insert after the `plugins {}` block (line 6) and before the `android {}` block (line 7):

```kotlin
import java.util.Properties

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
}
```

- [ ] **Step 2: Add release signing config inside android {} block**

Insert after `defaultConfig {}` and before `buildTypes {}`:

```kotlin
    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String?
                keyPassword = keystoreProperties["keyPassword"] as String?
                storeFile = keystoreProperties["storeFile"]?.let { rootProject.file(it) }
                storePassword = keystoreProperties["storePassword"] as String?
            }
        }
    }
```

- [ ] **Step 3: Replace the debug signingConfig in the release build type**

Change this line in `buildTypes { release { ... } }`:
```kotlin
signingConfig = signingConfigs.getByName("debug")
```
To:
```kotlin
signingConfig = signingConfigs.getByName("release")
```

- [ ] **Step 4: Verify the full build.gradle.kts is syntactically correct**

Read the file after edits. The full structure should be:

```
plugins { ... }
import java.util.Properties
val keystoreProperties = ...
android {
    namespace = ...
    compileSdk = ...
    ndkVersion = ...
    compileOptions { ... }
    kotlinOptions { ... }
    defaultConfig { ... }
    signingConfigs { create("release") { ... } }
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(...)
        }
    }
}
dependencies { ... }
flutter { ... }
```

---

### Task 4: Add flutter_dotenv dependency

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Add flutter_dotenv to dependencies**

In `pubspec.yaml`, add under `dependencies:` (after `connectivity_plus`):

```yaml
  flutter_dotenv: ^5.2.1
```

- [ ] **Step 2: Declare .env as an asset**

In `pubspec.yaml`, under `flutter: > assets:`, add:

```yaml
    - .env
```

The assets section should now look like:

```yaml
flutter:
  uses-material-design: true
  assets:
    - .env
    - assets/banners/
    - assets/decorations/
    - assets/generated/
    - assets/icons/
    - assets/images/
```

- [ ] **Step 3: Run pub get to install**

```bash
flutter pub get
```

Expected: Exit code 0, no errors. Output confirms `flutter_dotenv` is resolved.

---

### Task 5: Create .env, .env.template, and update .gitignore

**Files:**
- Create: `.env` (never committed, contains real secrets)
- Create: `.env.template` (committed, shows required vars without secrets)
- Modify: `.gitignore`

- [ ] **Step 1: Create .env.template**

Write `.env.template`:

```
# Vertiege environment configuration
# Copy this file to .env and fill in your values
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
```

- [ ] **Step 2: Create .env with real values**

Write `.env`:

```
SUPABASE_URL=<your-actual-supabase-url>
SUPABASE_ANON_KEY=<your-actual-anon-key>
```

Replace with the real values currently passed via `--dart-define` or environment variables.

- [ ] **Step 3: Add .env to .gitignore**

Add to `.gitignore`:

```
# Environment file (contains secrets)
.env
```

- [ ] **Step 4: Verify .gitignore**

```bash
git check-ignore .env
```

Expected: `.env` is listed (it is ignored).

- [ ] **Step 5: Commit the template and gitignore changes**

```bash
git add .env.template .gitignore
git commit -m "chore: add .env.template and gitignore for dotenv migration"
```

---

### Task 6: Update main.dart to use flutter_dotenv

**Files:**
- Modify: `lib/main.dart`

- [ ] **Step 1: Replace compile-time env vars with dotenv**

Replace the entire contents of `lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  final url = dotenv.env['SUPABASE_URL'] ?? '';
  final anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  if (url.isEmpty || anonKey.isEmpty) {
    throw Exception(
      'Missing SUPABASE_URL or SUPABASE_ANON_KEY in .env file. '
      'Copy .env.template to .env and fill in your values.',
    );
  }

  await Supabase.initialize(url: url, anonKey: anonKey);

  runApp(const ProviderScope(child: VirtualStatusWorldsApp()));
}
```

- [ ] **Step 2: Verify the app compiles**

```bash
flutter analyze lib/main.dart
```

Expected: No errors. Warnings about unused imports from the old code should be gone (the old code had no import warnings, the new one won't either since we're replacing the old `String.fromEnvironment` with `dotenv`).

- [ ] **Step 3: Commit**

```bash
git add lib/main.dart pubspec.yaml pubspec.lock .env.template .gitignore
git commit -m "refactor: migrate env vars from compile-time to flutter_dotenv"
```

---

### Task 7: Build signed release APK

**Files:**
- Creates: `build/app/outputs/flutter-apk/app-release.apk`

- [ ] **Step 1: Clean previous builds**

```bash
flutter clean
```

Expected: Clean exit, removes `build/` directory.

- [ ] **Step 2: Build the release APK**

```bash
flutter build apk --release
```

Expected: Build succeeds. Output ends with something like:
```
Running Gradle task 'assembleRelease'... Done
✓ Built build/app/outputs/flutter-apk/app-release.apk (<size>MB)
```

- [ ] **Step 3: Verify the APK is signed with release key**

```bash
keytool -printcert -jarfile build/app/outputs/flutter-apk/app-release.apk 2>/dev/null || \
  (unzip -p build/app/outputs/flutter-apk/app-release.apk META-INF/*.RSA | keytool -printcert)
```

Alternative — check with `apksigner` if Android SDK tools are available:
```bash
$ANDROID_HOME/build-tools/*/apksigner verify --verbose build/app/outputs/flutter-apk/app-release.apk
```

Expected: Certificate info matches the upload keystore (same org name, validity dates). The APK is verified as signed.

- [ ] **Step 4: Commit build config changes**

```bash
git add android/app/build.gradle.kts
git commit -m "feat: configure Android release signing with keystore"
```

---

### Task 8: iOS signing skeleton

**Files:**
- Modify: `ios/Flutter/Release.xcconfig`
- Create: `ios/fastlane/Appfile` (optional but recommended)

- [ ] **Step 1: Confirm bundle identifier**

The bundle ID in Android is `com.imma96.virtual_status_worlds`. This needs to match iOS. Check the current iOS bundle ID:

```bash
grep -r "PRODUCT_BUNDLE_IDENTIFIER" ios/ || echo "Not explicitly set — using Flutter default"
```

If not set, note that the default Flutter iOS bundle ID comes from the project name. Check `ios/Runner.xcodeproj/project.pbxproj`:

```bash
grep "PRODUCT_BUNDLE_IDENTIFIER" ios/Runner.xcodeproj/project.pbxproj | head -1
```

- [ ] **Step 2: Create a basic Release.xcconfig for future iOS signing**

Replace `ios/Flutter/Release.xcconfig`:

```
#include "Generated.xcconfig"

// Release signing — fill in when iOS build is needed
// DEVELOPMENT_TEAM = <your-team-id>
// PROVISIONING_PROFILE_SPECIFIER = <your-profile-specifier>
```

- [ ] **Step 3: Commit**

```bash
git add ios/Flutter/Release.xcconfig
git commit -m "chore: add iOS release signing skeleton"
```

---

### Task 9: Verify end-to-end on a device

- [ ] **Step 1: Install on a connected Android device**

```bash
flutter install --release
```

Or manually install the APK:

```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

Expected: APK installs without "signature verification" errors. App launches.

- [ ] **Step 2: Smoke test**

1. App launches → splash screen visible
2. Auth screen loads (login/signup)
3. Sign in with test account
4. Main feed appears
5. Tap through bottom nav tabs

- [ ] **Step 3: Verify Supabase connection**

Check that the app can reach Supabase — the feed loads data. If the app crashes on launch, double-check that `.env` is properly bundled as an asset and the values are correct (Task 6).

---

### Task 10: Document keystore backup

**Files:**
- Create: `docs/superpowers/specs/keystore-backup.md`

- [ ] **Step 1: Write backup instructions**

Write `docs/superpowers/specs/keystore-backup.md`:

```markdown
# Keystore Backup

The Android release keystore is at `android/upload-keystore.jks`.

## Recovery

Without this file, you cannot publish updates to the same app. Store a copy securely:
- Password manager (1Password, Bitwarden) — store the .jks file and passwords
- Encrypted cloud backup
- Offline USB drive

## Credentials

| Field | Value |
|-------|-------|
| Keystore file | android/upload-keystore.jks |
| Key alias | upload |
| Validity | 10000 days (~27 years) |
| Key algorithm | RSA 2048 |

Store passwords separately from the keystore file.
```

- [ ] **Step 2: Commit**

```bash
git add docs/superpowers/specs/keystore-backup.md
git commit -m "docs: add keystore backup instructions"
```

---

## Phase 1 Completion Checklist

- [ ] Release keystore generated and backed up
- [ ] `key.properties` created (not committed)
- [ ] `build.gradle.kts` uses release signing for release builds
- [ ] `.env` created with live Supabase credentials (not committed)
- [ ] `.env.template` committed for team reference
- [ ] `main.dart` migrated to `flutter_dotenv`
- [ ] Signed release APK builds successfully
- [ ] APK installs and runs on a real Android device
- [ ] iOS signing skeleton in place
- [ ] Keystore backup documented
