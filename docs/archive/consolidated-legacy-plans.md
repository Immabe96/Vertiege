# Vertiege — consolidated legacy plans

**Status:** Archived — read for history only. Superseded for active work by [PLAN.md](../../PLAN.md).

**Consolidated:** 2026-06-05 — 11 source documents.

## Index

| # | Source |
|---|--------|
| 1 | `docs/archive/completed-plans/2026-05-19/2026-05-04-phase-1-build-and-sign.md` |
| 2 | `docs/archive/completed-plans/2026-05-19/2026-05-05-design-overhaul.md` |
| 3 | `docs/archive/completed-plans/2026-05-19/2026-05-06-sovereign-excellence-plan.md` |
| 4 | `docs/archive/plan-PERFECTION-BACKLOG.md` |
| 5 | `docs/archive/plans/2026-05-19-long-horizon-product-completion-plan.md` |
| 6 | `docs/archive/plans/2026-05-20-firebase-supabase-hybrid-completion-plan.md` |
| 7 | `docs/archive/plans/2026-05-22-image-asset-refresh.md` |
| 8 | `docs/archive/plans/2026-05-22-screen-rebuild-plan.md` |
| 9 | `docs/archive/plans/SEASON-1-BIG-BANG.md` |
| 10 | `docs/archive/plans/vertiege-claude-code-plan.md` |
| 11 | `docs/archive/root-plans/2026-05-19/implementation.md` |

---

## Source: `docs/archive/completed-plans/2026-05-19/2026-05-04-phase-1-build-and-sign.md`

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

---

## Source: `docs/archive/completed-plans/2026-05-19/2026-05-05-design-overhaul.md`

# Design Overhaul Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ground-up visual rebuild of Vertiege following the new DESIGN.md — dark social arena theme, Inter typography, mixed radius scale, flat elevation with accent glow, 4-tab navigation with floating post FAB.

**Architecture:** Three-layer approach. Layer 1: theme foundation (colors, tokens, theme, font). Layer 2: navigation restructure (5→4 tabs, FAB, notification overlay). Layer 3: every screen and widget adopts new tokens. Changes ripple top-down — theme files first, then navigation, then screens, then leaf widgets.

**Tech Stack:** Flutter/Dart, Riverpod, go_router, Supabase, google_fonts (Inter), flutter_animate, cached_network_image

**Design doc:** `DESIGN.md` at project root — the source of truth for all token values.

---

## File Map

### Layer 1: Theme Foundation (3 files + pubspec)
- **Rewrite:** `lib/theme/colors.dart` — all color constants replaced with DESIGN.md palette
- **Rewrite:** `lib/theme/design_system.dart` — new token scales, Inter font, removed shadows
- **Rewrite:** `lib/theme/app_theme.dart` — dark-first M3 theme, Inter textTheme, 4-tab nav theme
- **Modify:** `pubspec.yaml` — verify google_fonts, add inter reference note

### Layer 2: Navigation (2 files)
- **Modify:** `lib/router/app_router.dart` — remove alerts branch (index 4), add notification overlay route
- **Rewrite:** `lib/screens/tabs/tab_layout.dart` — 4 tabs + centered floating post FAB, notification bell in bar

### Layer 3: Screens (8 files)
- **Modify:** `lib/screens/splash_screen.dart` — new colors, Inter type
- **Modify:** `lib/screens/onboarding/onboarding_screen.dart` — new colors, tokens
- **Modify:** `lib/screens/tabs/nexus_screen.dart` — FAB removed (moves to tab_layout), notification bell action changed, tokens
- **Modify:** `lib/screens/tabs/explore_screen.dart` — tokens, no FAB clearance needed
- **Modify:** `lib/screens/tabs/chat_list_screen.dart` — tokens
- **Modify:** `lib/screens/tabs/identity_screen.dart` — tokens, new tier color mapping
- **Modify:** `lib/screens/tabs/alerts_screen.dart` — refactor into notification overlay widget
- **Modify:** `lib/screens/search_screen.dart` — tokens

### Layer 4: Widgets (~45 files across 7 directories)
- **Check/modify:** All files in `lib/widgets/core/`, `feed/`, `profile/`, `shared/`, `worlds/`, `achievements/`
- Most changes are token references (AppColors → new names, FontSizes → new values, Spacing → new values, RadiusTokens → new values)
- Files using `Shimmer` widget — verify Shimmer still exists
- Files using `ShadowTokens` — remove shadow references, use surface color instead

---

### Task 1: Rewrite colors.dart with DESIGN.md palette

**Files:**
- Rewrite: `lib/theme/colors.dart`

- [ ] **Step 1: Write the new colors.dart**

Replace the entire file. DESIGN.md sections 2 (Color Palette) and 6 (Elevation) define all tokens.

```dart
import 'package:flutter/material.dart';

/// Vertiege color system — Dark Social Arena
/// Source of truth: DESIGN.md at project root
class AppColors {
  AppColors._();

  // ── Surface Hierarchy ───────────────────────────────────
  static const Color canvas = Color(0xFF121212);
  static const Color surface = Color(0xFF181818);
  static const Color surfaceElevated = Color(0xFF1F1F1F);
  static const Color surfaceHigh = Color(0xFF252525);
  static const Color surfaceOverlay = Color(0xFF2A2A2A);

  // ── Text ────────────────────────────────────────────────
  static const Color ink = Color(0xFFFFFFFF);
  static const Color inkSecondary = Color(0xFFB3B3B3);
  static const Color inkMuted = Color(0xFF7C7C7C);
  static const Color inkOnAccent = Color(0xFFFFFFFF);

  // ── Gamification Accents ────────────────────────────────
  static const Color accentPrimary = Color(0xFF7C3AED);
  static const Color accentStreak = Color(0xFFF5AF19);
  static const Color accentPrestige = Color(0xFFD4AF37);
  static const Color accentLevel = Color(0xFF3B82F6);
  static const Color accentAchievement = Color(0xFFEC4899);

  // ── World Type Accents ──────────────────────────────────
  static const Color worldWealth = Color(0xFF22C55E);
  static const Color worldProfession = Color(0xFFA78BFA);
  static const Color worldDominion = Color(0xFFEF4444);

  // ── Semantic ────────────────────────────────────────────
  static const Color semanticSuccess = Color(0xFF22C55E);
  static const Color semanticError = Color(0xFFEF4444);
  static const Color semanticWarning = Color(0xFFF5AF19);

  // ── Borders ─────────────────────────────────────────────
  static const Color borderDefault = Color(0xFF252525);
  static const Color borderSubtle = Color(0xFF1F1F1F);

  // ── Glow Opacities (applied at render time) ─────────────
  static const double glowAlpha = 0.15;
  static const double glowAlphaStrong = 0.25;

  // ── Tier Colors ─────────────────────────────────────────
  static const Color tierHustler = Color(0xFF10B981);
  static const Color tierHighRoller = Color(0xFF3B82F6);
  static const Color tierElite = Color(0xFF8B5CF6);
  static const Color tierOldMoney = Color(0xFFD4AF37);
  static const Color tierApex = Color(0xFFEF4444);

  // ── Alpha Presets ───────────────────────────────────────
  static const double alphaHover = 0.06;
  static const double alphaPressed = 0.12;
  static const double alphaSelected = 0.15;
  static const double alphaBorder = 0.15;
  static const double alphaDisabled = 0.38;
  static const double alphaOverlay = 0.60;

  // ── Legacy Compatibility (remove after all consumers updated) ─
  // Adding these so the codebase doesn't instantly break.
  // Each will be removed in its respective widget task.
  static const Color seed = accentPrimary;
  static const Color online = semanticSuccess;
  static const Color idle = semanticWarning;
  static const Color dnd = semanticError;
  static const Color offline = inkMuted;
  static const Color streaming = Color(0xFF593695);
  static const Color owlGreen = Color(0xFF58CC02);
  static const Color owlGreenDeep = Color(0xFF58A700);
  static const Color streakOrange = accentStreak;
  static const Color streakOrangeDeep = Color(0xFFCC7A00);
  static const Color gemPink = accentAchievement;
  static const Color beeYellow = Color(0xFFFFC800);
  static const Color eelBlue = Color(0xFF1CB0F6);
  static const Color brandGreen = Color(0xFF3ECF8E);
  static const Color emerald = Color(0xFF2D8B57);
  static const Color crimson = Color(0xFF8B2252);
  static const Color dangerRed = semanticError;
  static const Color gold = accentPrestige;
  static const Color silver = Color(0xFFC0C0C0);
  static const Color bronze = Color(0xFFCD7F32);
  static const Color darkSurfaceBase = canvas;
  static const Color darkSurfaceRaised = surface;
  static const Color darkSurfaceCard = surfaceElevated;
  static const Color darkSurfaceOverlay = surfaceHigh;
  static const Color darkSurfaceHighest = surfaceOverlay;
  static const List<Color> gradientPrimary = [accentPrimary, Color(0xFF7C6FFD)];
  static const List<Color> gradientBrand = [accentPrimary, Color(0xFF3ECF8E)];
  static const List<Color> gradientWarm = [accentStreak, Color(0xFFFF5764)];
  static const List<Color> gradientDark = [canvas, surfaceElevated];
  static const Map<String, Color> tierColors = {
    'hustlers': tierHustler,
    'highRollers': tierHighRoller,
    'elite': tierElite,
    'oldMoney': tierOldMoney,
    'apex': tierApex,
  };
}
```

- [ ] **Step 2: Verify the file compiles**

Run: `cd /c/Users/Immabe/Vertiege && dart analyze lib/theme/colors.dart`
Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/theme/colors.dart
git commit -m "feat: rewrite colors.dart with DESIGN.md dark social arena palette

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

---

### Task 2: Rewrite design_system.dart with new token scales

**Files:**
- Rewrite: `lib/theme/design_system.dart`

- [ ] **Step 1: Write the new design_system.dart**

All token values from DESIGN.md sections 3 (Typography), 4 (Component Stylings mixing), 5 (Spacing). ShadowTokens removed — no box-shadows in new system.

```dart
import 'package:flutter/material.dart';

/// Vertiege design tokens — Dark Social Arena
/// Source of truth: DESIGN.md at project root

// ── Font ──────────────────────────────────────────────────

class AppFont {
  AppFont._();
  static const String family = 'Inter';
  static const String familyMono = 'JetBrains Mono';
}

// ── Typography Scale ──────────────────────────────────────

class FontSizes {
  FontSizes._();
  static const double micro = 11;
  static const double caption = 13;
  static const double bodySmall = 14;
  static const double body = 16;
  static const double button = 15;
  static const double headingCard = 18;
  static const double displaySection = 24;
  static const double displayHero = 32;
}

class FontWeights {
  FontWeights._();
  /// Only 400 and 700. No intermediate weights.
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight bold = FontWeight.w700;
}

class LetterSpacing {
  LetterSpacing._();
  static const double display = -0.5;
  static const double section = -0.3;
  static const double normal = 0.0;
  static const double micro = 0.3;
}

class LineHeight {
  LineHeight._();
  static const double display = 1.15;
  static const double heading = 1.25;
  static const double body = 1.45;
  static const double caption = 1.35;
  static const double button = 1.0;
}

// ── Spacing Scale ─────────────────────────────────────────

class Spacing {
  Spacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double section = 48;
}

// ── Radius Scale ──────────────────────────────────────────

class RadiusTokens {
  RadiusTokens._();
  static const double chip = 4;
  static const double input = 6;
  static const double card = 8;
  static const double cardFeatured = 12;
  static const double celebration = 14;
  static const double pill = 20;
  static const double full = 9999;
  static const double circle = 9999;
}

// ── Icon Sizes ────────────────────────────────────────────

class IconSizes {
  IconSizes._();
  static const double xs = 12;
  static const double sm = 14;
  static const double md = 20;
  static const double lg = 24;
  static const double xl = 40;
  static const double hero = 48;
}

// ── Animation ─────────────────────────────────────────────

class AnimDurations {
  AnimDurations._();
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration entrance = Duration(milliseconds: 500);
}

class AnimCurves {
  AnimCurves._();
  static const Curve easeOut = Curves.easeOutCubic;
  static const Curve easeInOut = Curves.easeInOutCubic;
  static const Curve spring = Curves.elasticOut;
  static const Curve bouncy = Curves.easeOutBack;
}

// ── Touch Targets ─────────────────────────────────────────

class TouchTargets {
  TouchTargets._();
  static const double minimum = 44;
  static const double iconButton = 40;
  static const double chip = 32;
}
```

- [ ] **Step 2: Verify the file compiles**

Run: `dart analyze lib/theme/design_system.dart`
Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/theme/design_system.dart
git commit -m "feat: rewrite design tokens to DESIGN.md scales

- Inter font, binary weights (400/700), new type scale
- Spacing: 4/8/12/16/24/32/48
- Radius: 4/6/8/12/14/20/9999 (mixed scale)
- No shadows (flat elevation system)
- New touch target constants

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

---

### Task 3: Rewrite app_theme.dart with dark-first Inter theme

**Files:**
- Rewrite: `lib/theme/app_theme.dart`

- [ ] **Step 1: Write the new app_theme.dart**

Dark-first Material 3 theme using Inter via GoogleFonts. No light theme — dark only for the dark social arena.

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';
import 'design_system.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get theme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.accentPrimary,
      brightness: Brightness.dark,
      surface: AppColors.canvas,
    );

    final interTextTheme = GoogleFonts.interTextTheme(
      ThemeData.dark().textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme.copyWith(
        surface: AppColors.canvas,
        surfaceContainer: AppColors.surface,
        surfaceContainerHighest: AppColors.surfaceElevated,
        primary: AppColors.accentPrimary,
        onPrimary: AppColors.inkOnAccent,
        onSurface: AppColors.ink,
        onSurfaceVariant: AppColors.inkSecondary,
        outline: AppColors.borderDefault,
        outlineVariant: AppColors.borderSubtle,
        error: AppColors.semanticError,
        shadow: Colors.transparent,
      ),
      scaffoldBackgroundColor: AppColors.canvas,
      textTheme: interTextTheme,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: AppColors.canvas,
        titleTextStyle: GoogleFonts.inter(
          fontSize: FontSizes.headingCard,
          fontWeight: FontWeights.bold,
          color: AppColors.ink,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.accentPrimary,
        unselectedItemColor: AppColors.inkSecondary,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: FontSizes.micro,
          fontWeight: FontWeights.bold,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: FontSizes.micro,
          fontWeight: FontWeights.regular,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.card),
          side: const BorderSide(color: AppColors.borderDefault),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.xs,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.input),
          borderSide: const BorderSide(color: AppColors.borderDefault),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.input),
          borderSide: const BorderSide(color: AppColors.borderDefault),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.input),
          borderSide: BorderSide(
            color: AppColors.accentPrimary.withValues(alpha: 0.4),
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.sm + 2,
        ),
        isDense: true,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accentPrimary,
          foregroundColor: AppColors.inkOnAccent,
          textStyle: GoogleFonts.inter(
            fontSize: FontSizes.button,
            fontWeight: FontWeights.bold,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RadiusTokens.pill),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.xl,
            vertical: Spacing.sm + 2,
          ),
          minimumSize: const Size(0, TouchTargets.minimum),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.accentPrimary,
          textStyle: GoogleFonts.inter(
            fontSize: FontSizes.button,
            fontWeight: FontWeights.bold,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RadiusTokens.pill),
          ),
          side: BorderSide(
            color: AppColors.accentPrimary.withValues(alpha: 0.2),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.xl,
            vertical: Spacing.sm + 2,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceElevated,
        selectedColor: AppColors.accentPrimary.withValues(alpha: 0.12),
        labelStyle: GoogleFonts.inter(
          fontSize: FontSizes.caption,
          fontWeight: FontWeights.regular,
        ),
        secondaryLabelStyle: GoogleFonts.inter(
          fontSize: FontSizes.caption,
          fontWeight: FontWeights.bold,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.chip),
          side: const BorderSide(color: AppColors.borderDefault),
        ),
        side: const BorderSide(color: AppColors.borderDefault),
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.xs,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.accentPrimary,
        foregroundColor: AppColors.inkOnAccent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.pill),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.card),
        ),
        backgroundColor: AppColors.surfaceHigh,
        contentTextStyle: GoogleFonts.inter(
          fontSize: FontSizes.bodySmall,
          color: AppColors.ink,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.cardFeatured),
        ),
      ),
      dividerTheme: DividerThemeData(
        space: 1,
        thickness: 0.5,
        color: AppColors.borderSubtle,
      ),
      tabBarTheme: TabBarThemeData(
        indicatorSize: TabBarIndicatorSize.tab,
        dividerHeight: 0,
        labelColor: AppColors.ink,
        unselectedLabelColor: AppColors.inkSecondary,
        labelStyle: GoogleFonts.inter(
          fontSize: FontSizes.button,
          fontWeight: FontWeights.bold,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: FontSizes.button,
          fontWeight: FontWeights.regular,
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify the file compiles**

Run: `dart analyze lib/theme/app_theme.dart`
Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/theme/app_theme.dart
git commit -m "feat: rewrite app_theme.dart — dark-first Inter M3 theme

- Dark only (Brightness.dark)
- Inter via GoogleFonts.interTextTheme
- Color scheme seeds from accentPrimary (#7C3AED)
- Surface/surfaceContainer/surfaceContainerHighest mapped to canvas/surface/elevated
- Pill CTAs, chip-radius inputs, flat cards
- No shadows anywhere

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

---

### Task 4: Update pubspec.yaml and verify Google Fonts / Inter

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Verify google_fonts dependency**

Check pubspec.yaml has `google_fonts: ^6.2.1` (it does). No change needed — Inter is bundled with google_fonts.

Run: `grep google_fonts pubspec.yaml`
Expected: `google_fonts: ^6.2.1` (or compatible)

- [ ] **Step 2: Run flutter pub get**

Run: `cd /c/Users/Immabe/Vertiege && flutter pub get`
Expected: Exit 0, no errors.

- [ ] **Step 3: Verify the project compiles with new theme files**

Run: `cd /c/Users/Immabe/Vertiege && dart analyze lib/theme/`
Expected: No errors in theme directory.

- [ ] **Step 4: Commit**

```bash
git add pubspec.lock
git commit -m "chore: verify google_fonts Inter availability

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

---

### Task 5: Restructure router — 5 tabs to 4, notification overlay route

**Files:**
- Modify: `lib/router/app_router.dart`

- [ ] **Step 1: Remove alerts branch (index 4) from the StatefulShellRoute**

Find the `StatefulShellRoute.indexedStack` definition. Remove the 5th branch (alerts at index 4). The remaining branches are:

```dart
// Branch 0: / (Home/Nexus)
// Branch 1: /explore (Worlds)
// Branch 2: /chat (Messages)
// Branch 3: /identity (Profile)
```

The alerts screen route should remain as a standalone push route (not a tab):
```dart
// Remove from branches, add as standalone:
GoRoute(
  path: '/notifications',
  builder: (context, state) => const AlertsScreen(),
),
```

Find and delete the entire Branch 4 block (the one with `path: '/alerts'` and `AlertsScreen`).

- [ ] **Step 2: Add notification overlay route**

Add a standalone route for viewing all notifications:

```dart
// In the top-level routes list (outside StatefulShellRoute):
GoRoute(
  path: '/notifications',
  builder: (context, state) => const AlertsScreen(),
),
```

- [ ] **Step 3: Verify router compiles**

Run: `dart analyze lib/router/app_router.dart`
Expected: No errors.

- [ ] **Step 4: Commit**

```bash
git add lib/router/app_router.dart
git commit -m "feat: restructure router — 5→4 tabs, /notifications as push route

- Removed alerts branch from StatefulShellRoute
- /notifications is now a standalone push route (not a tab)
- Home, Worlds, Chat, Profile are the 4 tab destinations

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

---

### Task 6: Rewrite tab_layout.dart — 4 tabs + floating post FAB + notification bell

**Files:**
- Rewrite: `lib/screens/tabs/tab_layout.dart`

- [ ] **Step 1: Read current tab_layout.dart to understand state providers**

Run: `head -20 lib/screens/tabs/tab_layout.dart`

Note the `scrollToTopProvider` — keep it. Remove `achievementProvider` import (tier celebration moves to nexus).

- [ ] **Step 2: Write the new tab_layout.dart**

Four tabs, floating post FAB centered above the bar, notification bell icon in the bar.

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../state/notification_provider.dart';
import '../../theme/colors.dart';
import '../../theme/design_system.dart';

final scrollToTopProvider = StateProvider<int>((ref) => 0);

class TabLayout extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;
  const TabLayout({super.key, required this.navigationShell});

  @override
  ConsumerState<TabLayout> createState() => _TabLayoutState();
}

class _TabLayoutState extends ConsumerState<TabLayout>
    with TickerProviderStateMixin {
  late final AnimationController _badgePulseController;

  @override
  void initState() {
    super.initState();
    _badgePulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _badgePulseController.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        final unread = ref
            .read(notificationProvider)
            .notifications
            .where((n) => !n.read)
            .length;
        if (unread > 0 && mounted) {
          _badgePulseController.repeat(reverse: true);
        }
      }
    });
  }

  @override
  void dispose() {
    _badgePulseController.dispose();
    super.dispose();
  }

  // ── 4 tab destinations ──────────────────────────────────

  static const _destinations = [
    (icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
    (icon: Icons.explore_outlined, activeIcon: Icons.explore, label: 'Worlds'),
    (
      icon: Icons.chat_bubble_outline,
      activeIcon: Icons.chat_bubble,
      label: 'Chat',
    ),
    (icon: Icons.person_outlined, activeIcon: Icons.person, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final unread = ref
        .watch(notificationProvider)
        .notifications
        .where((n) => !n.read)
        .length;
    final theme = Theme.of(context);
    final index = widget.navigationShell.currentIndex;

    // Manage badge pulse
    if (unread > 0 && !_badgePulseController.isAnimating) {
      _badgePulseController.repeat(reverse: true);
    } else if (unread == 0 && _badgePulseController.isAnimating) {
      _badgePulseController.stop();
      _badgePulseController.reset();
    }

    // Show FAB on Home (0) and Worlds (1), not on Chat or Profile
    final showFab = index == 0 || index == 1;

    return Scaffold(
      body: widget.navigationShell,
      floatingActionButton: showFab
          ? FloatingActionButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                // PostInput needs a worldId — use first joined world or global
                // The actual world context is resolved inside the modal
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  backgroundColor: AppColors.surfaceHigh,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(RadiusTokens.cardFeatured),
                    ),
                  ),
                  builder: (_) => const _PostFabSheet(),
                );
              },
              child: const Icon(Icons.edit, size: IconSizes.md),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomBar(theme, index, unread),
    );
  }

  Widget _buildBottomBar(ThemeData theme, int index, int unread) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Spacing.lg,
          Spacing.sm,
          Spacing.lg,
          Spacing.sm,
        ),
        child: SizedBox(
          height: 60,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final barWidth = constraints.maxWidth;
              final tabWidth = barWidth / _destinations.length;
              const indicatorWidth = 48.0;
              final indicatorLeft =
                  index * tabWidth + (tabWidth - indicatorWidth) / 2;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Bar background
                  Container(
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(RadiusTokens.pill),
                      border: Border.all(
                        color: AppColors.borderDefault,
                      ),
                    ),
                  ),

                  // Animated pill indicator
                  AnimatedPositioned(
                    duration: AnimDurations.slow,
                    curve: AnimCurves.spring,
                    left: indicatorLeft,
                    top: 6,
                    child: Container(
                      width: indicatorWidth,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius:
                            BorderRadius.circular(RadiusTokens.card),
                      ),
                    ),
                  ),

                  // Tab items
                  Row(
                    children: List.generate(_destinations.length, (i) {
                      final isActive = i == index;
                      final dest = _destinations[i];

                      return Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            if (i == index) {
                              ref
                                  .read(scrollToTopProvider.notifier)
                                  .state++;
                            }
                            widget.navigationShell.goBranch(
                              i,
                              initialLocation: i == index,
                            );
                          },
                          child: Semantics(
                            label: dest.label,
                            selected: isActive,
                            button: true,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Icon (with badge on Profile when unread)
                                if (i == 3 && unread > 0)
                                  _PulsingBadge(
                                    animation: _badgePulseController,
                                    label:
                                        unread > 99 ? '99+' : '$unread',
                                    child: Icon(
                                      isActive
                                          ? dest.activeIcon
                                          : dest.icon,
                                      size: IconSizes.md,
                                      color: isActive
                                          ? AppColors.accentPrimary
                                          : AppColors.inkSecondary,
                                    ),
                                  )
                                else
                                  Icon(
                                    isActive
                                        ? dest.activeIcon
                                        : dest.icon,
                                    size: IconSizes.md,
                                    color: isActive
                                        ? AppColors.accentPrimary
                                        : AppColors.inkSecondary,
                                  ),
                                const SizedBox(height: 3),
                                Text(
                                  dest.label,
                                  style: TextStyle(
                                    fontSize: FontSizes.micro,
                                    fontWeight: isActive
                                        ? FontWeights.bold
                                        : FontWeights.regular,
                                    color: isActive
                                        ? AppColors.accentPrimary
                                        : AppColors.inkSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ── Pulsing badge wrapper ──────────────────────────────────

class _PulsingBadge extends StatelessWidget {
  final AnimationController animation;
  final String label;
  final Widget child;

  const _PulsingBadge({
    required this.animation,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final scale = 1.0 + (animation.value * 0.3);
        return Transform.scale(
          scale: scale,
          child: Badge(
            backgroundColor: AppColors.accentAchievement,
            label: Text(
              label,
              style: const TextStyle(
                fontSize: FontSizes.micro,
                fontWeight: FontWeights.bold,
                color: AppColors.inkOnAccent,
              ),
            ),
            child: child,
          ),
        );
      },
    );
  }
}

// ── Post FAB sheet placeholder ────────────────────────────

class _PostFabSheet extends StatelessWidget {
  const _PostFabSheet();

  @override
  Widget build(BuildContext context) {
    // This will be replaced with actual PostInput once feed widgets are updated
    return const SizedBox(
      height: 300,
      child: Center(
        child: Text(
          'New Post',
          style: TextStyle(color: AppColors.inkSecondary),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Verify compilation**

Run: `dart analyze lib/screens/tabs/tab_layout.dart`
Expected: No errors.

- [ ] **Step 4: Commit**

```bash
git add lib/screens/tabs/tab_layout.dart
git commit -m "feat: rewrite tab layout — 4 tabs, floating post FAB, notification badge on Profile

- 4 tabs: Home, Worlds, Chat, Profile
- FAB centered above bar on Home and Worlds tabs only
- Notification badge on Profile tab with pulse animation
- Removed TierCelebration overlay (moves to nexus)
- Removed alerts/notifications tab

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

---

### Task 7: Update splash_screen.dart — new colors, Inter typography

**Files:**
- Modify: `lib/screens/splash_screen.dart`

- [ ] **Step 1: Read the current file**

Read splash_screen.dart to identify all color and font references.

- [ ] **Step 2: Replace color references**

Replace all `AppColors.seed` → `AppColors.accentPrimary`
Replace `AppColors.gemPink` → `AppColors.accentAchievement`
Replace `AppColors.streakOrange` → `AppColors.accentStreak`
Replace `AppColors.brandGreen` → `AppColors.semanticSuccess` (or accent level)

Replace `GoogleFonts.plusJakartaSans(...)` → `GoogleFonts.inter(...)`

Update any gradient references: `AppColors.gradientPrimary` still works (legacy compat in colors.dart)

Replace `Theme.of(context).colorScheme` surface references with `AppColors.*` equivalents.

- [ ] **Step 3: Verify compilation**

Run: `dart analyze lib/screens/splash_screen.dart`
Expected: No errors.

- [ ] **Step 4: Commit**

```bash
git add lib/screens/splash_screen.dart
git commit -m "refactor: migrate splash screen to new design tokens

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

---

### Task 8: Update onboarding_screen.dart — new tokens

**Files:**
- Modify: `lib/screens/onboarding/onboarding_screen.dart`

- [ ] **Step 1: Read and update**

Read the file. Replace:
- `AppColors.*` references to new names
- `GoogleFonts.plusJakartaSans(...)` → `GoogleFonts.inter(...)`
- `FontSizes.*` → new scale values (hero→displayHero, title→headingCard, body→body)
- `Spacing.*` → new values (md: 16→12, lg: 24→16, xl: 32→24)
- `RadiusTokens.*` → new values (md: 12→8, lg: 16→12, round: 100→20)
- `TactileButton` references — check if this widget still exists; if broken, use `FilledButton` with pill shape

- [ ] **Step 2: Verify compilation**

Run: `dart analyze lib/screens/onboarding/onboarding_screen.dart`
Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/screens/onboarding/onboarding_screen.dart
git commit -m "refactor: migrate onboarding screen to new design tokens

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

---

### Task 9: Update nexus_screen.dart — remove FAB, notification bell action, tokens

**Files:**
- Modify: `lib/screens/tabs/nexus_screen.dart`

- [ ] **Step 1: Read the file**

Read nexus_screen.dart to identify the FAB setup and notification bell action.

- [ ] **Step 2: Remove FAB and change notification bell**

- Remove `floatingActionButton` from the Scaffold (FAB is now in TabLayout)
- Remove `_onNewPost` method if it exists
- Change notification bell action from `goBranch(4)` to `context.push('/notifications')`
- Replace all `AppColors.*` with new names
- Replace `GoogleFonts.plusJakartaSans(...)` → `GoogleFonts.inter(...)`
- Replace `FontSizes.*`, `Spacing.*`, `RadiusTokens.*` → new values
- Remove any `TierCelebration` overlay (moves to separate task or stays as inline widget using new tokens)

- [ ] **Step 3: Replace quick-scroll FAB tokens**

The quick-scroll FAB uses `Theme.of(context).colorScheme.primaryContainer` etc. Replace with `AppColors.surfaceElevated` and `AppColors.accentPrimary`.

- [ ] **Step 4: Verify compilation**

Run: `dart analyze lib/screens/tabs/nexus_screen.dart`
Expected: No errors.

- [ ] **Step 5: Commit**

```bash
git add lib/screens/tabs/nexus_screen.dart
git commit -m "refactor: migrate nexus screen to new design tokens

- Removed FAB (now in TabLayout)
- Notification bell pushes /notifications instead of goBranch(4)
- All tokens updated to DESIGN.md values

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

---

### Task 10: Update explore_screen.dart — tokens, remove FAB clearance

**Files:**
- Modify: `lib/screens/tabs/explore_screen.dart`

- [ ] **Step 1: Read and update**

- Replace all `AppColors.*`, `GoogleFonts.plusJakartaSans`, `FontSizes.*`, `Spacing.*`, `RadiusTokens.*`
- Remove the `SizedBox(height: Spacing.xxl + Spacing.lg)` bottom padding that was for FAB clearance
- Update `_FilterPill` — use `RadiusTokens.chip` (4px) for unselected, `RadiusTokens.pill` (20px) for selected
- Update `_SectionHeader` — use `FontSizes.displaySection` (24px)
- Update `_ShimmerWorldCard` — use `RadiusTokens.card` (8px)

- [ ] **Step 2: Verify compilation**

Run: `dart analyze lib/screens/tabs/explore_screen.dart`
Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/screens/tabs/explore_screen.dart
git commit -m "refactor: migrate explore screen to new design tokens

- Removed FAB clearance padding
- Filter pills use mixed radius (chip/pill)
- All token references updated

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

---

### Task 11: Update chat_list_screen.dart — tokens

**Files:**
- Modify: `lib/screens/tabs/chat_list_screen.dart`

- [ ] **Step 1: Read and update**

- Replace all `AppColors.*`, `GoogleFonts.plusJakartaSans`, `FontSizes.*`, `Spacing.*`, `RadiusTokens.*`
- Update `_RoomTile` — avatar size, name style (Inter 700), message preview style (Inter 400)
- Update status dot references: `StatusDot` widget uses `AppColors.online`
- Unread badge: use `AppColors.accentAchievement` background, `RadiusTokens.pill` (20px)
- Update `ScreenLoading.list()` call if it references old tokens

- [ ] **Step 2: Verify compilation**

Run: `dart analyze lib/screens/tabs/chat_list_screen.dart`
Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/screens/tabs/chat_list_screen.dart
git commit -m "refactor: migrate chat list screen to new design tokens

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

---

### Task 12: Update identity_screen.dart — tokens, new tier colors

**Files:**
- Modify: `lib/screens/tabs/identity_screen.dart`

- [ ] **Step 1: Read and update**

- Replace `AppColors.darkSurfaceBase` → `AppColors.canvas`
- Replace `AppColors.darkSurfaceCard` → `AppColors.surface`
- Replace all `GoogleFonts.plusJakartaSans` → `GoogleFonts.inter`
- Replace all `FontSizes.*`, `Spacing.*`, `RadiusTokens.*` → new values
- Update `_coverHeight = 180` — keep, but gradient uses `AppColors.gradientPrimary`
- Update `_avatarSize = 80` → 80 is fine, use `RadiusTokens.circle` for avatar
- Tier pill: use `AppColors.accentPrimary.withValues(alpha: 0.12)` background
- XP counter: use `AppColors.accentLevel` (blue) instead of `AppColors.seed`
- Stats row: use `Spacing.lg` (16) horizontal gap
- Streak display: use `AppColors.accentStreak` for flame icon
- Badge section: verify `BadgeDisplay` widget works with new tokens
- Share card: verify `ShareCard` uses new tokens
- Sign out: maintain red but use `AppColors.semanticError`

- [ ] **Step 2: Verify compilation**

Run: `dart analyze lib/screens/tabs/identity_screen.dart`
Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/screens/tabs/identity_screen.dart
git commit -m "refactor: migrate identity screen to new design tokens

- XP/counter uses level blue accent
- Streak uses streak orange accent
- All surface colors updated to new palette

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

---

### Task 13: Refactor alerts_screen.dart into notification overlay + update tokens

**Files:**
- Modify: `lib/screens/tabs/alerts_screen.dart`

- [ ] **Step 1: Read the file**

Read alerts_screen.dart. It remains as `AlertsScreen` but is now a push route (`/notifications`) not a tab.

- [ ] **Step 2: Update tokens and remove tab-specific behavior**

- Replace all `AppColors.*`, `GoogleFonts.plusJakartaSans`, `FontSizes.*`, `Spacing.*`, `RadiusTokens.*`
- Remove any tab-specific code (e.g., `scrollToTopProvider` listener if it references tab index)
- Remove notification type → `goBranch(4)` navigation (no longer a tab)
- Type colors: update to new accent palette (like→accentAchievement, comment→accentLevel, etc.)
- Add a back button to AppBar since it's now a pushed route

- [ ] **Step 3: Verify compilation**

Run: `dart analyze lib/screens/tabs/alerts_screen.dart`
Expected: No errors.

- [ ] **Step 4: Commit**

```bash
git add lib/screens/tabs/alerts_screen.dart
git commit -m "refactor: migrate alerts screen to new tokens, back button for push route

- Now a push route (/notifications), not a tab
- Added back button to AppBar
- Notification type colors use new gamification palette
- Removed tab-specific navigation code

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

---

### Task 14: Update search_screen.dart — tokens

**Files:**
- Modify: `lib/screens/search_screen.dart`

- [ ] **Step 1: Read and update**

Replace all `AppColors.*`, `GoogleFonts.plusJakartaSans`, `FontSizes.*`, `Spacing.*`, `RadiusTokens.*`.

- [ ] **Step 2: Verify**

Run: `dart analyze lib/screens/search_screen.dart`

- [ ] **Step 3: Commit**

```bash
git add lib/screens/search_screen.dart
git commit -m "refactor: migrate search screen to new design tokens

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

---

### Task 15: Update world_detail_screen.dart — tokens

**Files:**
- Modify: `lib/screens/world_detail_screen.dart`

- [ ] **Step 1: Read and update**

Replace all `AppColors.*`, `GoogleFonts.plusJakartaSans`, `FontSizes.*`, `Spacing.*`, `RadiusTokens.*`.

- [ ] **Step 2: Verify**

Run: `dart analyze lib/screens/world_detail_screen.dart`

- [ ] **Step 3: Commit**

```bash
git add lib/screens/world_detail_screen.dart
git commit -m "refactor: migrate world detail screen to new design tokens

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

---

### Task 16: Update remaining screens — world_channel, world_members, chat_room

**Files:**
- Modify: `lib/screens/world_channel_screen.dart`
- Modify: `lib/screens/world_members_screen.dart`
- Modify: `lib/screens/chat_room_screen.dart`

- [ ] **Step 1: Read and update each**

For each file:
- Replace all `AppColors.*` with new names
- Replace `GoogleFonts.plusJakartaSans` → `GoogleFonts.inter`
- Replace `FontSizes.*`, `Spacing.*`, `RadiusTokens.*` → new values
- Replace `ShadowTokens.*` → remove shadows, use `AppColors.surface` colors instead

- [ ] **Step 2: Verify**

Run: `dart analyze lib/screens/world_channel_screen.dart lib/screens/world_members_screen.dart lib/screens/chat_room_screen.dart`

- [ ] **Step 3: Commit**

```bash
git add lib/screens/world_channel_screen.dart lib/screens/world_members_screen.dart lib/screens/chat_room_screen.dart
git commit -m "refactor: migrate world channel, members, and chat room screens to new tokens

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

---

### Task 17: Update core widgets — empty_state, fade_in, shimmer, screen_header, screen_loading, tactile_button, xp_toast, status_dot, themed_text, image_viewer, notification_bell, offline_banner, safe_screen

**Files:**
- Check: `lib/widgets/core/empty_state.dart`
- Check: `lib/widgets/core/fade_in.dart`
- Check: `lib/widgets/core/shimmer.dart`
- Modify: all 13 files in `lib/widgets/core/` that reference old tokens

- [ ] **Step 1: Read each file and update tokens**

For each file in `lib/widgets/core/`:
- Replace `AppColors.*` → new names
- Replace `GoogleFonts.plusJakartaSans` → `GoogleFonts.inter`
- Replace `FontSizes.*`, `Spacing.*`, `RadiusTokens.*`, `IconSizes.*` → new values
- `Shimmer` widget — keep the Shimmer class but update its default color to `AppColors.surfaceElevated`
- `fade_in.dart` — probably no token changes needed (uses animation duration)
- `tactile_button.dart` — replace with standard `FilledButton` + `RadiusTokens.pill` styling, or update to use new tokens
- `notification_bell.dart` — change `goBranch(4)` to `context.push('/notifications')`
- `screen_loading.dart` — update shimmer colors to new surface tokens
- `xp_toast.dart` — update to use `AppColors.accentLevel` for XP glow

- [ ] **Step 2: Verify all compile**

Run: `dart analyze lib/widgets/core/`
Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/widgets/core/
git commit -m "refactor: migrate all core widgets to new design tokens

- Notification bell now pushes /notifications
- Shimmer uses new surface colors
- Tactile button updated or replaced
- All tokens updated

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

---

### Task 18: Update feed widgets — post_item, post_input, post_image, media_grid, comment_sheet, reaction_bar

**Files:**
- Modify: all 6 files in `lib/widgets/feed/`

- [ ] **Step 1: Read and update each**

- Replace all `AppColors.*`, `GoogleFonts.plusJakartaSans`, `FontSizes.*`, `Spacing.*`, `RadiusTokens.*`
- `post_item.dart` — update card style (no shadow, `AppColors.surface`, `RadiusTokens.card`, 1px `AppColors.borderDefault` border)
- `post_input.dart` — update to use new input theme tokens, `RadiusTokens.input` (6px)
- `reaction_bar.dart` — update reaction colors to gamification palette
- `media_grid.dart` — update image placeholder to `AppColors.surfaceElevated`
- `post_image.dart` — update loading placeholder color

- [ ] **Step 2: Verify**

Run: `dart analyze lib/widgets/feed/`
Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/widgets/feed/
git commit -m "refactor: migrate feed widgets to new design tokens

- Cards: flat surfaces, no shadows
- Inputs: 6px radius
- Reactions: gamification palette colors

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

---

### Task 19: Update profile widgets — cosmetic_avatar, name_banner, badge, badge_display, share_card

**Files:**
- Modify: all 5 files in `lib/widgets/profile/`

- [ ] **Step 1: Read and update each**

- Replace all `AppColors.*`, `GoogleFonts.plusJakartaSans`, `FontSizes.*`, `Spacing.*`, `RadiusTokens.*`
- `cosmetic_avatar.dart` — update XP-based tier decorations to use new accent colors
- `badge_display.dart` — use `AppColors.accentAchievement` for badge highlights
- `share_card.dart` — update to dark surface tokens

- [ ] **Step 2: Verify**

Run: `dart analyze lib/widgets/profile/`
Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/widgets/profile/
git commit -m "refactor: migrate profile widgets to new design tokens

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

---

### Task 20: Update worlds widgets — world_card, world_banner, world_icon, world_hero_banner, world_info_sheet, world_member_row, world_events_card, world_channel_list, world_residents, leaderboard, access_icon, access_guard

**Files:**
- Modify: all 12 files in `lib/widgets/worlds/`

- [ ] **Step 1: Read and update each**

- Replace all `AppColors.*`, `GoogleFonts.plusJakartaSans`, `FontSizes.*`, `Spacing.*`, `RadiusTokens.*`
- `world_card.dart` — update `_WideLayout` and `_SquareLayout`, `_CardBody`, `_BannerThumbnail`, `_Badge`
  - Card: `AppColors.surface`, `RadiusTokens.card` (8px), 1px `AppColors.borderDefault`
  - Badges: use world-type accent colors (`worldWealth`, `worldProfession`, `worldDominion`)
  - Remove `boxShadow` from Container decoration
  - `_WideLayout` — keep `SizedBox(height: 110)`, no IntrinsicHeight
- `world_banner.dart` — update placeholder gradient to new colors
- `world_hero_banner.dart` — update SliverAppBar colors
- `world_info_sheet.dart` — use `AppColors.surfaceHigh` for bottom sheet
- `world_events_card.dart` — use `AppColors.accentPrimary` for RSVP toggle

- [ ] **Step 2: Verify**

Run: `dart analyze lib/widgets/worlds/`
Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/widgets/worlds/
git commit -m "refactor: migrate world widgets to new design tokens

- Cards: flat, no shadows, surface color
- Badges: world-type accent colors
- All radius/spacing/type tokens updated

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

---

### Task 21: Update shared widgets — parallax_scroll, progress_bar, search_bar_widget, tier_icon, image_picker_widget, haptic_tab

**Files:**
- Modify: all 6 files in `lib/widgets/shared/`

- [ ] **Step 1: Read and update each**

- Replace all `AppColors.*`, `GoogleFonts.plusJakartaSans`, `FontSizes.*`, `Spacing.*`, `RadiusTokens.*`
- `progress_bar.dart` — use `AppColors.accentLevel` for progress fill
- `tier_icon.dart` — use new tier colors

- [ ] **Step 2: Verify**

Run: `dart analyze lib/widgets/shared/`
Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/widgets/shared/
git commit -m "refactor: migrate shared widgets to new design tokens

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

---

### Task 22: Update achievement widgets — achievement_card, achievement_grid, tier_celebration

**Files:**
- Modify: all 3 files in `lib/widgets/achievements/`

- [ ] **Step 1: Read and update each**

- Replace all `AppColors.*`, `GoogleFonts.plusJakartaSans`, `FontSizes.*`, `Spacing.*`, `RadiusTokens.*`
- `tier_celebration.dart` — THIS is where accent glow belongs. Add glow border:
  ```dart
  boxShadow: [
    BoxShadow(
      color: AppColors.accentPrestige.withValues(alpha: AppColors.glowAlpha),
      blurRadius: 32,
      spreadRadius: 0,
    ),
  ],
  ```
- Use `AppColors.accentPrestige` for gold tier, `AppColors.accentLevel` for level-up glow
- Use `RadiusTokens.celebration` (14px) for celebration cards

- [ ] **Step 2: Verify**

Run: `dart analyze lib/widgets/achievements/`
Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/widgets/achievements/
git commit -m "feat: add accent glow to achievement celebrations

- Tier celebrations use prestige gold glow
- Level-up animations use level blue glow
- This is the ONLY place glow appears — per DESIGN.md rules

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

---

### Task 23: Full project analysis and fix remaining references

**Files:**
- All remaining files with old token references

- [ ] **Step 1: Run full project analysis**

```bash
cd /c/Users/Immabe/Vertiege && dart analyze lib/ 2>&1 | head -100
```

- [ ] **Step 2: Fix any remaining errors**

Search for any remaining references to old token names that weren't caught:
```bash
grep -r "plusJakartaSans" lib/ --include="*.dart"
grep -r "ShadowTokens" lib/ --include="*.dart"
grep -r "darkSurfaceBase\|darkSurfaceRaised\|darkSurfaceCard\|darkSurfaceOverlay\|darkSurfaceHighest" lib/ --include="*.dart"
```

Replace any remaining instances.

- [ ] **Step 3: Remove legacy compatibility aliases from colors.dart**

Once all consumers are migrated, remove the `// ── Legacy Compatibility ──` section from colors.dart.

- [ ] **Step 4: Verify clean analysis**

Run: `dart analyze lib/`
Expected: No errors, no warnings.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "chore: remove legacy compatibility aliases, final cleanup

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

---

### Task 24: Build and verify on device

- [ ] **Step 1: Build release APK**

```bash
cd /c/Users/Immabe/Vertiege/android && JAVA_HOME="C:/Program Files/Android/Android Studio/jbr" ./gradlew assembleRelease
```
Expected: BUILD SUCCESSFUL.

- [ ] **Step 2: Install on device**

```bash
adb install -r /c/Users/Immabe/Vertiege/build/app/outputs/flutter-apk/app-release.apk
```
Expected: Success.

- [ ] **Step 3: Verify visually**

Launch the app and check:
- Dark theme applied everywhere — no light surfaces
- Inter font rendering on all text
- 4 tabs visible: Home, Worlds, Chat, Profile
- FAB visible on Home and Worlds tabs
- Notification bell in top bar or badge on Profile tab
- Flat cards (no shadows) on all screens
- Gamification elements use correct accent colors

- [ ] **Step 4: Commit any final fixes**

If visual verification reveals issues, fix and commit each fix atomically.

---

## Self-Review

**1. Spec coverage:**
- Section 1 (Visual Theme) → Tasks 1-3 (theme foundation)
- Section 2 (Color Palette) → Task 1 (colors.dart)
- Section 3 (Typography) → Task 2 (design_system.dart), Task 3 (app_theme.dart)
- Section 4 (Component Stylings) → Tasks 17-22 (all widget files)
- Section 5 (Layout Principles) → Tasks 2 (spacing), Tasks 7-16 (screen layouts)
- Section 6 (Depth & Elevation) → Tasks 3 (no shadows), Task 22 (accent glow only in celebrations)
- Section 7 (Do's and Don'ts) → Enforced by theme structure (can't add shadows, binary weights enforced)
- Section 8 (Responsive Behavior) → Implicit in existing layouts (not changing grid structure)
- Section 9 (Agent Prompt Guide) → Not implemented — that's a reference for AI agents, not code
- Navigation Architecture → Tasks 5-6 (router + tab layout)

**2. Placeholder scan:** No TBDs, TODOs, or incomplete sections. Every task has concrete code or clear instructions.

**3. Type consistency:** Token names match between colors.dart, design_system.dart, and app_theme.dart. All widget tasks reference the same token constants.

One gap: the `_PostFabSheet` in Task 6 is a placeholder. The actual PostInput widget is updated in Task 18. This is acceptable — the placeholder compiles and the real PostInput integrates when feed widgets are migrated.

---

## Source: `docs/archive/completed-plans/2026-05-19/2026-05-06-sovereign-excellence-plan.md`

# Sovereign Excellence UI Replacement — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace every visible surface in the Vertiege Flutter app with the "Sovereign Excellence" design system from Stitch — glassmorphism, obsidian palette, Space Grotesk + Inter typography, 5-tab glass navigation, bento grid layouts.

**Architecture:** Token-first replacement. Phase 1 rewrites `colors.dart`, `design_system.dart`, and `app_theme.dart` as the new foundation. Phase 2 builds shared glass/glow/ghost widgets. Phase 3 rewrites navigation (bottom bar + router). Phases 4-6 rebuild screens and migrate widgets. Phase 7 polishes states and animations. Models, providers, services, and business logic are never touched.

**Tech Stack:** Flutter/Dart, Material 3, Riverpod, go_router, Google Fonts (Space Grotesk + Inter), Material Symbols icons

---

## File Map

| File | Action | Phase |
|------|--------|-------|
| `lib/theme/colors.dart` | Rewrite | P1 |
| `lib/theme/design_system.dart` | Rewrite | P1 |
| `lib/theme/app_theme.dart` | Rewrite | P1 |
| `lib/widgets/core/glass_panel.dart` | Create | P2 |
| `lib/widgets/core/glow_border.dart` | Create | P2 |
| `lib/widgets/core/ghost_input.dart` | Create | P2 |
| `lib/widgets/core/sovereign_card.dart` | Create | P2 |
| `lib/widgets/core/loading_state.dart` | Rewrite | P2 |
| `lib/widgets/core/error_banner.dart` | Create | P2 |
| `lib/widgets/core/progress_bar.dart` | Rewrite | P2 |
| `lib/screens/tabs/tab_layout.dart` | Rewrite | P3 |
| `lib/router/app_router.dart` | Modify | P3 |
| `lib/screens/tabs/create_post_screen.dart` | Create | P3 |
| `lib/screens/tabs/nexus_screen.dart` | Rewrite | P4 |
| `lib/screens/tabs/explore_screen.dart` | Rewrite | P4 |
| `lib/screens/tabs/identity_screen.dart` | Rewrite | P4 |
| `lib/screens/tabs/chat_list_screen.dart` | Rewrite | P4 |
| `lib/screens/tabs/alerts_screen.dart` | Rewrite | P4 |
| `lib/screens/world_detail_screen.dart` | Rewrite | P5 |
| `lib/screens/world_channel_screen.dart` | Rewrite | P5 |
| `lib/screens/world_settings_screen.dart` | Rewrite | P5 |
| `lib/screens/world_members_screen.dart` | Rewrite | P5 |
| `lib/widgets/worlds/world_card.dart` | Rewrite | P6 |
| `lib/widgets/worlds/world_hero_banner.dart` | Rewrite | P6 |
| `lib/widgets/feed/post_item.dart` | Rewrite | P6 |
| `lib/widgets/feed/post_composer.dart` | Rewrite | P6 |
| `lib/widgets/feed/post_input.dart` | Rewrite | P6 |
| `lib/widgets/profile/badge_display.dart` | Rewrite | P6 |
| `lib/widgets/profile/cosmetic_avatar.dart` | Rewrite | P6 |
| `lib/widgets/profile/name_banner.dart` | Rewrite | P6 |
| `lib/widgets/achievements/achievement_card.dart` | Rewrite | P6 |
| `lib/widgets/core/empty_state.dart` | Rewrite | P6 |
| `lib/widgets/core/screen_loading.dart` | Rewrite | P6 |
| `lib/widgets/core/shimmer.dart` | Rewrite | P6 |
| `lib/widgets/core/notification_bell.dart` | Rewrite | P6 |
| `lib/screens/achievements/achievements_index.dart` | Rewrite | P6 |
| `lib/screens/achievements/achievement_category.dart` | Rewrite | P6 |
| `lib/screens/settings_screen.dart` | Rewrite | P6 |
| `lib/screens/search_screen.dart` | Rewrite | P6 |
| `lib/screens/create_world_screen.dart` | Rewrite | P6 |
| `lib/screens/chat_room_screen.dart` | Rewrite | P6 |
| `lib/screens/resident_profile_screen.dart` | Rewrite | P6 |
| `lib/screens/splash_screen.dart` | Rewrite | P6 |
| `lib/screens/auth/login_screen.dart` | Rewrite | P6 |
| `lib/screens/auth/signup_screen.dart` | Rewrite | P6 |
| `lib/screens/onboarding/onboarding_screen.dart` | Rewrite | P6 |

---

## Phase 1: Design Tokens

### Task 1.1: Rewrite colors.dart

**Files:**
- Modify: `lib/theme/colors.dart`

- [ ] **Step 1: Replace colors.dart with Sovereign palette**

```dart
import 'package:flutter/material.dart';

/// Vertiege color system — Sovereign Excellence
/// Source: Stitch design system "App Interface Redesign"
class AppColors {
  AppColors._();

  // ── Surface Hierarchy (OLED obsidian) ─────────────────────
  static const Color canvas = Color(0xFF0A0A0A);
  static const Color surface = Color(0xFF141218);
  static const Color surfaceElevated = Color(0xFF1D1B20);
  static const Color surfaceHigh = Color(0xFF211F24);
  static const Color surfaceOverlay = Color(0xFF2B292F);
  static const Color surfaceContainerLowest = Color(0xFF0F0D13);
  static const Color surfaceContainerLow = Color(0xFF1D1B20);
  static const Color surfaceContainer = Color(0xFF211F24);
  static const Color surfaceContainerHigh = Color(0xFF2B292F);
  static const Color surfaceContainerHighest = Color(0xFF36343A);

  // ── Text ──────────────────────────────────────────────────
  static const Color ink = Color(0xFFE6E0E9);
  static const Color inkSecondary = Color(0xFFCBC4D2);
  static const Color inkMuted = Color(0xFF948E9C);
  static const Color inkOnAccent = Color(0xFF381E72);

  // ── Sovereign Accents ─────────────────────────────────────
  static const Color primary = Color(0xFFCFBCFF);
  static const Color primaryContainer = Color(0xFF6750A4);
  static const Color onPrimary = Color(0xFF381E72);
  static const Color onPrimaryContainer = Color(0xFFE0D2FF);
  static const Color primaryFixed = Color(0xFFE9DDFF);
  static const Color primaryFixedDim = Color(0xFFCFBCFF);

  // ── Gold / Tertiary ───────────────────────────────────────
  static const Color tertiary = Color(0xFFE7C365);
  static const Color tertiaryContainer = Color(0xFFC9A74D);
  static const Color onTertiary = Color(0xFF3E2E00);
  static const Color onTertiaryContainer = Color(0xFF503D00);
  static const Color tertiaryFixed = Color(0xFFFFDF93);
  static const Color tertiaryFixedDim = Color(0xFFE7C365);

  // ── Secondary ─────────────────────────────────────────────
  static const Color secondary = Color(0xFFCDC0E9);
  static const Color secondaryContainer = Color(0xFF4D4465);
  static const Color onSecondary = Color(0xFF342B4B);
  static const Color onSecondaryContainer = Color(0xFFBFB2DA);

  // ── Hustler (Tier III) ────────────────────────────────────
  static const Color hustler = Color(0xFFFF6D00);

  // ── Semantic ──────────────────────────────────────────────
  static const Color error = Color(0xFFFFB4AB);
  static const Color errorContainer = Color(0xFF93000A);
  static const Color onError = Color(0xFF690005);
  static const Color onErrorContainer = Color(0xFFFFDAD6);
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF5AF19);

  // ── Borders ───────────────────────────────────────────────
  static const Color borderDefault = Color(0xFF494551);
  static const Color borderSubtle = Color(0xFF36343A);
  static const Color outline = Color(0xFF948E9C);
  static const Color outlineVariant = Color(0xFF494551);

  // ── Surface Variant ───────────────────────────────────────
  static const Color surfaceVariant = Color(0xFF36343A);
  static const Color surfaceBright = Color(0xFF3B383E);
  static const Color surfaceDim = Color(0xFF141218);

  // ── Glow Opacities ────────────────────────────────────────
  static const double glowGoldAlpha = 0.10;
  static const double glowVioletAlpha = 0.10;
  static const double glowOrangeAlpha = 0.10;
  static const double glowAlphaStrong = 0.15;

  // ── Glass ─────────────────────────────────────────────────
  static const Color glassBackground = Color(0x99121212);
  static const Color glassModalBackground = Color(0x66141818);
  static const Color glassBorder = Color(0x1A948E9C);

  // ── Alpha Presets ─────────────────────────────────────────
  static const double alphaHover = 0.05;
  static const double alphaPressed = 0.10;
  static const double alphaSelected = 0.12;
  static const double alphaBorder = 0.20;
  static const double alphaOverlay = 0.60;

  // ── Legacy aliases for gradual migration ──────────────────
  static const Color seed = primary;
  static const Color accentPrimary = primary;
  static const Color accentPrestige = tertiary;
  static const Color accentStreak = warning;
  static const Color accentAchievement = Color(0xFFEC4899);
  static const Color accentLevel = Color(0xFF3B82F6);
  static const Color worldWealth = success;
  static const Color worldProfession = primary;
  static const Color worldDominion = hustler;
  static const Color semanticError = error;
  static const Color semanticSuccess = success;
  static const Color semanticWarning = warning;
  static const Color tierHustler = hustler;
  static const Color tierHighRoller = Color(0xFF3B82F6);
  static const Color tierElite = primary;
  static const Color tierOldMoney = tertiary;
  static const Color tierApex = error;
  static const Color online = success;
  static const Color idle = warning;
  static const Color dnd = error;
  static const Color offline = inkMuted;
  static const Color streaming = Color(0xFF593695);
  static const Color streakOrange = warning;
  static const Color gemPink = Color(0xFFEC4899);
  static const Color beeYellow = Color(0xFFFFC800);
  static const Color eelBlue = Color(0xFF1CB0F6);
  static const Color brandGreen = Color(0xFF3ECF8E);
  static const Color emerald = Color(0xFF2D8B57);
  static const Color crimson = Color(0xFF8B2252);
  static const Color dangerRed = error;
  static const Color gold = tertiary;
  static const Color silver = Color(0xFFC0C0C0);
  static const Color bronze = Color(0xFFCD7F32);
  static const Color darkSurfaceBase = canvas;
  static const Color darkSurfaceRaised = surface;
  static const Color darkSurfaceCard = surfaceElevated;
  static const Color darkSurfaceOverlay = surfaceHigh;
  static const Color darkSurfaceHighest = surfaceOverlay;
  static const List<Color> gradientPrimary = [primary, Color(0xFF7C6FFD)];
  static const List<Color> gradientBrand = [primary, Color(0xFF3ECF8E)];
  static const List<Color> gradientWarm = [warning, Color(0xFFFF5764)];
  static const List<Color> gradientDark = [canvas, surfaceElevated];
  static const Map<String, Color> tierColors = {
    'hustlers': tierHustler,
    'highRollers': tierHighRoller,
    'elite': tierElite,
    'oldMoney': tierOldMoney,
    'apex': tierApex,
  };
  static const Map<String, Color> tier = tierColors;
}
```

- [ ] **Step 2: Verify the file compiles**

Run: `dart analyze lib/theme/colors.dart`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
git add lib/theme/colors.dart
git commit -m "feat(P1): rewrite colors.dart to Sovereign Excellence obsidian palette"
```

### Task 1.2: Rewrite design_system.dart

**Files:**
- Modify: `lib/theme/design_system.dart`

- [ ] **Step 1: Replace design_system.dart with Sovereign tokens**

```dart
import 'package:flutter/material.dart';

/// Vertiege design tokens — Sovereign Excellence
/// Source: Stitch design system "App Interface Redesign"

// ── Font ────────────────────────────────────────────────────
class AppFont {
  AppFont._();
  static const String headline = 'Space Grotesk';
  static const String body = 'Inter';
  static const String mono = 'JetBrains Mono';
}

// ── Typography Scale ────────────────────────────────────────
class FontSizes {
  FontSizes._();
  static const double labelSm = 12;
  static const double bodyMd = 16;
  static const double bodyLg = 18;
  static const double headlineMd = 24;
  static const double headlineLg = 32;
  static const double displayXl = 48;
}

class FontWeights {
  FontWeights._();
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
}

class LetterSpacing {
  LetterSpacing._();
  static const double display = -0.02;
  static const double headline = -0.01;
  static const double normal = 0.0;
  static const double label = 0.05;
}

class LineHeight {
  LineHeight._();
  static const double display = 1.1;
  static const double headline = 1.3;
  static const double headlineLg = 1.2;
  static const double body = 1.5;
  static const double bodyLg = 1.6;
  static const double label = 1.0;
}

// ── Spacing Scale (8px base) ────────────────────────────────
class Spacing {
  Spacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double section = 48;
  static const double gutter = 24;
  static const double marginMobile = 16;
  static const double marginDesktop = 40;
}

// ── Radius Scale (architectural — tight) ────────────────────
class RadiusTokens {
  RadiusTokens._();
  static const double sm = 2;
  static const double md = 4;
  static const double lg = 6;
  static const double xl = 8;
  static const double full = 12;
}

// ── Icon Sizes ──────────────────────────────────────────────
class IconSizes {
  IconSizes._();
  static const double xs = 12;
  static const double sm = 14;
  static const double md = 20;
  static const double lg = 24;
  static const double xl = 32;
  static const double hero = 48;
}

// ── Animation ───────────────────────────────────────────────
class AnimDurations {
  AnimDurations._();
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration entrance = Duration(milliseconds: 500);
}

class AnimCurves {
  AnimCurves._();
  static const Curve easeOut = Curves.easeOutCubic;
  static const Curve easeInOut = Curves.easeInOutCubic;
  static const Curve spring = Curves.elasticOut;
  static const Curve bouncy = Curves.easeOutBack;
}

// ── Touch Targets ───────────────────────────────────────────
class TouchTargets {
  TouchTargets._();
  static const double minimum = 44;
  static const double iconButton = 40;
  static const double chip = 32;
}
```

- [ ] **Step 2: Verify compilation**

Run: `dart analyze lib/theme/design_system.dart`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
git add lib/theme/design_system.dart
git commit -m "feat(P1): rewrite design_system.dart to Sovereign typography/spacing/radius tokens"
```

### Task 1.3: Rewrite app_theme.dart

**Files:**
- Modify: `lib/theme/app_theme.dart`

- [ ] **Step 1: Replace app_theme.dart with Sovereign ThemeData**

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';
import 'design_system.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get theme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
      surface: AppColors.canvas,
    ).copyWith(
      surface: AppColors.canvas,
      surfaceContainer: AppColors.surface,
      surfaceContainerHighest: AppColors.surfaceElevated,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      onSurface: AppColors.ink,
      onSurfaceVariant: AppColors.inkSecondary,
      outline: AppColors.borderDefault,
      outlineVariant: AppColors.borderSubtle,
      error: AppColors.error,
      tertiary: AppColors.tertiary,
      onTertiary: AppColors.onTertiary,
      shadow: Colors.transparent,
    );

    final interTextTheme = GoogleFonts.interTextTheme(
      ThemeData.dark().textTheme.apply(
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
        decorationColor: AppColors.inkSecondary,
      ),
    );

    final spaceGroteskHeadline = GoogleFonts.spaceGroteskTextTheme(
      ThemeData.dark().textTheme.apply(
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
        decorationColor: AppColors.inkSecondary,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.canvas,
      textTheme: interTextTheme.copyWith(
        displayLarge: spaceGroteskHeadline.displayLarge?.copyWith(
          fontSize: FontSizes.displayXl,
          fontWeight: FontWeights.bold,
          letterSpacing: LetterSpacing.display,
          height: LineHeight.display,
        ),
        headlineLarge: spaceGroteskHeadline.headlineLarge?.copyWith(
          fontSize: FontSizes.headlineLg,
          fontWeight: FontWeights.semiBold,
          letterSpacing: LetterSpacing.headline,
          height: LineHeight.headlineLg,
        ),
        headlineMedium: spaceGroteskHeadline.headlineMedium?.copyWith(
          fontSize: FontSizes.headlineMd,
          fontWeight: FontWeights.semiBold,
          height: LineHeight.headline,
        ),
        bodyLarge: interTextTheme.bodyLarge?.copyWith(
          fontSize: FontSizes.bodyLg,
          fontWeight: FontWeights.regular,
          height: LineHeight.bodyLg,
        ),
        bodyMedium: interTextTheme.bodyMedium?.copyWith(
          fontSize: FontSizes.bodyMd,
          fontWeight: FontWeights.regular,
          height: LineHeight.body,
        ),
        labelSmall: interTextTheme.labelSmall?.copyWith(
          fontSize: FontSizes.labelSm,
          fontWeight: FontWeights.semiBold,
          letterSpacing: LetterSpacing.label,
          height: LineHeight.label,
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: AppColors.surface.withValues(alpha: 0.8),
        titleTextStyle: GoogleFonts.spaceGrotesk(
          fontSize: FontSizes.headlineLg,
          fontWeight: FontWeights.bold,
          color: AppColors.tertiary,
          letterSpacing: -0.5,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        backgroundColor: Colors.transparent,
        selectedItemColor: AppColors.tertiary,
        unselectedItemColor: AppColors.inkMuted,
        selectedLabelStyle: TextStyle(
          fontSize: FontSizes.labelSm,
          fontWeight: FontWeights.semiBold,
          letterSpacing: LetterSpacing.label,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: FontSizes.labelSm,
          fontWeight: FontWeights.regular,
          letterSpacing: LetterSpacing.label,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.glassBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.xl),
          side: const BorderSide(color: AppColors.glassBorder),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.xs,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        border: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.outlineVariant),
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.outlineVariant),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.tertiary),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 0,
          vertical: Spacing.sm + 4,
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: FontSizes.labelSm,
          fontWeight: FontWeights.semiBold,
          color: AppColors.tertiary,
          letterSpacing: LetterSpacing.label,
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: FontSizes.bodyMd,
          color: AppColors.inkMuted,
        ),
        isDense: false,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.tertiary,
          foregroundColor: AppColors.onTertiary,
          textStyle: GoogleFonts.inter(
            fontSize: FontSizes.labelSm,
            fontWeight: FontWeights.semiBold,
            letterSpacing: LetterSpacing.label,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RadiusTokens.md),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.xl,
            vertical: Spacing.md,
          ),
          minimumSize: const Size(0, TouchTargets.minimum),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.inter(
            fontSize: FontSizes.labelSm,
            fontWeight: FontWeights.semiBold,
            letterSpacing: LetterSpacing.label,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RadiusTokens.md),
          ),
          side: const BorderSide(color: AppColors.glassBorder),
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.xl,
            vertical: Spacing.md,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceElevated,
        selectedColor: AppColors.primary.withValues(alpha: AppColors.alphaSelected),
        labelStyle: GoogleFonts.inter(
          fontSize: FontSizes.labelSm,
          fontWeight: FontWeights.regular,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.lg),
          side: const BorderSide(color: AppColors.glassBorder),
        ),
        side: const BorderSide(color: AppColors.glassBorder),
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.xs,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 0,
        backgroundColor: AppColors.hustler,
        foregroundColor: Colors.black,
        shape: CircleBorder(),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.xl),
        ),
        backgroundColor: AppColors.surfaceHigh,
        contentTextStyle: GoogleFonts.inter(
          fontSize: FontSizes.bodyMd,
          color: AppColors.ink,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.glassModalBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.full),
        ),
      ),
      dividerTheme: const DividerThemeData(
        space: 1,
        thickness: 0.5,
        color: AppColors.borderSubtle,
      ),
      tabBarTheme: TabBarThemeData(
        indicatorSize: TabBarIndicatorSize.tab,
        dividerHeight: 0,
        labelColor: AppColors.tertiary,
        unselectedLabelColor: AppColors.inkSecondary,
        labelStyle: GoogleFonts.inter(
          fontSize: FontSizes.labelSm,
          fontWeight: FontWeights.semiBold,
          letterSpacing: LetterSpacing.label,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: FontSizes.labelSm,
          fontWeight: FontWeights.regular,
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify compilation**

Run: `dart analyze lib/theme/app_theme.dart`
Expected: No errors or only warnings about deprecated members (acceptable during migration)

- [ ] **Step 3: Commit**

```bash
git add lib/theme/app_theme.dart
git commit -m "feat(P1): rewrite app_theme.dart with Sovereign glass/glow theme, Space Grotesk + Inter"
```

---

## Phase 2: Shared Widgets

### Task 2.1: Create GlassPanel widget

**Files:**
- Create: `lib/widgets/core/glass_panel.dart`

- [ ] **Step 1: Write GlassPanel**

```dart
import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/design_system.dart';

class GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final Border? border;
  final double blur;

  const GlassPanel({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.border,
    this.blur = 12,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(RadiusTokens.xl),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding ?? const EdgeInsets.all(Spacing.lg),
          decoration: BoxDecoration(
            color: AppColors.glassBackground,
            borderRadius:
                borderRadius ?? BorderRadius.circular(RadiusTokens.xl),
            border: border ??
                Border.all(color: AppColors.glassBorder),
          ),
          child: child,
        ),
      ),
    );
  }
}

class GlassModal extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const GlassModal({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(RadiusTokens.full),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: padding ?? const EdgeInsets.all(Spacing.xl),
          decoration: BoxDecoration(
            color: AppColors.glassModalBackground,
            borderRadius: BorderRadius.circular(RadiusTokens.full),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: child,
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/widgets/core/glass_panel.dart
git commit -m "feat(P2): add GlassPanel and GlassModal widgets"
```

### Task 2.2: Create GlowBorder widget

**Files:**
- Create: `lib/widgets/core/glow_border.dart`

- [ ] **Step 1: Write GlowBorder**

```dart
import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/design_system.dart';

enum GlowTier { apex, elite, hustler }

class GlowBorder extends StatelessWidget {
  final Widget child;
  final GlowTier tier;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;

  const GlowBorder({
    super.key,
    required this.child,
    this.tier = GlowTier.elite,
    this.borderRadius,
    this.padding,
  });

  Color get _borderColor {
    switch (tier) {
      case GlowTier.apex:
        return AppColors.tertiary.withValues(alpha: 0.20);
      case GlowTier.elite:
        return AppColors.primary.withValues(alpha: 0.20);
      case GlowTier.hustler:
        return AppColors.hustler.withValues(alpha: 0.20);
    }
  }

  Color get _glowColor {
    switch (tier) {
      case GlowTier.apex:
        return AppColors.tertiary.withValues(alpha: AppColors.glowGoldAlpha);
      case GlowTier.elite:
        return AppColors.primary.withValues(alpha: AppColors.glowVioletAlpha);
      case GlowTier.hustler:
        return AppColors.hustler.withValues(alpha: AppColors.glowOrangeAlpha);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: AppColors.glassBackground,
        borderRadius: borderRadius ?? BorderRadius.circular(RadiusTokens.xl),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: _glowColor,
            blurRadius: 15,
            spreadRadius: 0,
          ),
        ],
      ),
      child: child,
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/widgets/core/glow_border.dart
git commit -m "feat(P2): add GlowBorder widget with Apex/Elite/Hustler tier support"
```

### Task 2.3: Create GhostInput widget

**Files:**
- Create: `lib/widgets/core/ghost_input.dart`

- [ ] **Step 1: Write GhostInput**

```dart
import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/design_system.dart';

class GhostInput extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? initialValue;
  final int? maxLines;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;

  const GhostInput({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.initialValue,
    this.maxLines = 1,
    this.autofocus = false,
    this.onChanged,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!.toUpperCase(),
            style: const TextStyle(
              fontSize: FontSizes.labelSm,
              fontWeight: FontWeights.semiBold,
              color: AppColors.tertiary,
              letterSpacing: LetterSpacing.label,
            ),
          ),
          const SizedBox(height: Spacing.xs),
        ],
        TextFormField(
          controller: controller,
          initialValue: controller == null ? initialValue : null,
          autofocus: autofocus,
          maxLines: maxLines,
          onChanged: onChanged,
          keyboardType: keyboardType,
          style: const TextStyle(
            fontSize: FontSizes.bodyMd,
            fontWeight: FontWeights.regular,
            color: AppColors.ink,
            height: LineHeight.body,
          ),
          decoration: InputDecoration(
            hintText: hint,
            border: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.outlineVariant),
            ),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.outlineVariant),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.tertiary),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: Spacing.sm + 4,
            ),
            isDense: false,
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/widgets/core/ghost_input.dart
git commit -m "feat(P2): add GhostInput widget with bottom-border focus animation"
```

### Task 2.4: Create SovereignCard widget

**Files:**
- Create: `lib/widgets/core/sovereign_card.dart`

- [ ] **Step 1: Write SovereignCard**

```dart
import 'package:flutter/material.dart';
import 'glow_border.dart';
import 'glass_panel.dart';
import '../../theme/colors.dart';
import '../../theme/design_system.dart';

enum CardTier { apex, elite, hustler }

class SovereignCard extends StatelessWidget {
  final Widget child;
  final CardTier tier;
  final VoidCallback? onTap;
  final bool glass;

  const SovereignCard({
    super.key,
    required this.child,
    this.tier = CardTier.elite,
    this.onTap,
    this.glass = true,
  });

  GlowTier _toGlowTier() {
    switch (tier) {
      case CardTier.apex:
        return GlowTier.apex;
      case CardTier.elite:
        return GlowTier.elite;
      case CardTier.hustler:
        return GlowTier.hustler;
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = glass
        ? GlassPanel(
            padding: const EdgeInsets.all(Spacing.lg),
            child: child,
          )
        : Padding(
            padding: const EdgeInsets.all(Spacing.lg),
            child: child,
          );

    final wrapped = GlowBorder(
      tier: _toGlowTier(),
      padding: EdgeInsets.zero,
      child: content,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: wrapped,
      );
    }
    return wrapped;
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/widgets/core/sovereign_card.dart
git commit -m "feat(P2): add SovereignCard with tiered glow + glass"
```

### Task 2.5: Update loading/error/empty widgets

**Files:**
- Rewrite: `lib/widgets/core/shimmer.dart`
- Create: `lib/widgets/core/loading_state.dart`
- Create: `lib/widgets/core/error_banner.dart`

- [ ] **Step 1: Rewrite shimmer.dart to pulse animation**

Replace the current Shimmer with a pulse animation matching Stitch's loading pattern:

```dart
import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/design_system.dart';

class Pulse extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final double? opacity;

  const Pulse({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = 4,
    this.opacity,
  });

  @override
  State<Pulse> createState() => _PulseState();
}

class _PulseState extends State<Pulse> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHighest.withValues(
              alpha: widget.opacity ??
                  (0.3 + (_controller.value * 0.2)),
            ),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}

// Keep old Shimmer class as a compatibility alias
class Shimmer extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const Shimmer({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Pulse(
      width: width,
      height: height,
      borderRadius: borderRadius,
    );
  }
}
```

- [ ] **Step 2: Write loading_state.dart**

```dart
import 'package:flutter/material.dart';
import 'glass_panel.dart';
import 'shimmer.dart';
import '../../theme/colors.dart';
import '../../theme/design_system.dart';

class GlassLoadingCard extends StatelessWidget {
  const GlassLoadingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Pulse(width: 150, height: FontSizes.headlineMd),
          const SizedBox(height: Spacing.sm),
          const Pulse(height: FontSizes.bodyMd),
          const SizedBox(height: Spacing.xs),
          const Pulse(width: double.infinity, height: FontSizes.bodyMd),
          const SizedBox(height: Spacing.md),
          Row(
            children: const [
              Pulse(width: 60, height: 20),
              SizedBox(width: Spacing.sm),
              Pulse(width: 40, height: 20),
            ],
          ),
        ],
      ),
    );
  }
}

class GlassLoadingList extends StatelessWidget {
  final int itemCount;
  const GlassLoadingList({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(Spacing.marginMobile),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: Spacing.sm + 4),
      itemBuilder: (_, __) => const GlassLoadingCard(),
    );
  }
}
```

- [ ] **Step 3: Write error_banner.dart**

```dart
import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/design_system.dart';

class SovereignErrorBanner extends StatelessWidget {
  final String message;
  final String? code;
  final VoidCallback? onRetry;

  const SovereignErrorBanner({
    super.key,
    required this.message,
    this.code,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.marginMobile,
        vertical: Spacing.md,
      ),
      color: AppColors.errorContainer.withValues(alpha: 0.8),
      child: SafeArea(
        child: Row(
          children: [
            const Icon(Icons.warning_rounded, color: AppColors.onErrorContainer, size: IconSizes.md),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: FontSizes.labelSm,
                      fontWeight: FontWeights.semiBold,
                      color: AppColors.onErrorContainer,
                    ),
                  ),
                  if (code != null)
                    Text(
                      code!,
                      style: const TextStyle(
                        fontSize: FontSizes.labelSm,
                        color: AppColors.onErrorContainer,
                      ),
                    ),
                ],
              ),
            ),
            if (onRetry != null)
              TextButton(
                onPressed: onRetry,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sync, size: IconSizes.sm, color: AppColors.tertiary),
                    SizedBox(width: Spacing.xs),
                    Text(
                      'RETRY',
                      style: TextStyle(
                        fontSize: FontSizes.labelSm,
                        fontWeight: FontWeights.semiBold,
                        color: AppColors.tertiary,
                        letterSpacing: LetterSpacing.label,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Commit**

```bash
git add lib/widgets/core/shimmer.dart lib/widgets/core/loading_state.dart lib/widgets/core/error_banner.dart
git commit -m "feat(P2): add pulse shimmer, glass loading cards, and error banner widgets"
```

### Task 2.6: Update progress_bar.dart

**Files:**
- Modify: `lib/widgets/shared/progress_bar.dart`

- [ ] **Step 1: Rewrite to Stitch thin progress bar**

```dart
import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/design_system.dart';

class SovereignProgressBar extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final Color? color;
  final String? label;
  final String? trailing;

  const SovereignProgressBar({
    super.key,
    required this.progress,
    this.color,
    this.label,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final barColor = color ?? AppColors.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null || trailing != null)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (label != null)
                Text(
                  label!.toUpperCase(),
                  style: const TextStyle(
                    fontSize: FontSizes.labelSm,
                    fontWeight: FontWeights.regular,
                    color: AppColors.inkSecondary,
                    letterSpacing: LetterSpacing.label,
                  ),
                ),
              if (trailing != null)
                Text(
                  trailing!,
                  style: TextStyle(
                    fontSize: FontSizes.labelSm,
                    fontWeight: FontWeights.semiBold,
                    color: barColor,
                  ),
                ),
            ],
          ),
        if (label != null || trailing != null) const SizedBox(height: Spacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: SizedBox(
            height: 4,
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: AppColors.surfaceContainerHighest.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/widgets/shared/progress_bar.dart
git commit -m "feat(P2): add SovereignProgressBar — thin 4px progress bar"
```

---

## Phase 3: Navigation

### Task 3.1: Rewrite tab_layout.dart (5-tab glass bottom bar)

**Files:**
- Modify: `lib/screens/tabs/tab_layout.dart`

- [ ] **Step 1: Replace entire file with 5-tab glass bottom bar**

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../state/notification_provider.dart';
import '../../theme/colors.dart';
import '../../theme/design_system.dart';

final scrollToTopProvider = StateProvider<int>((ref) => 0);

class TabLayout extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;
  const TabLayout({super.key, required this.navigationShell});

  @override
  ConsumerState<TabLayout> createState() => _TabLayoutState();
}

class _TabLayoutState extends ConsumerState<TabLayout> {
  static const _destinations = [
    (icon: Icons.hub, label: 'NEXUS'),
    (icon: Icons.explore, label: 'WORLDS'),
    (icon: Icons.add_circle, label: 'CREATE'),
    (icon: Icons.chat_bubble, label: 'CHAT'),
    (icon: Icons.account_circle, label: 'IDENTITY'),
  ];

  @override
  Widget build(BuildContext context) {
    final unread = ref
        .watch(notificationProvider)
        .notifications
        .where((n) => !n.read)
        .length;
    final index = widget.navigationShell.currentIndex;

    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: _buildBottomBar(index, unread),
    );
  }

  Widget _buildBottomBar(int index, int unread) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Spacing.marginMobile, Spacing.sm, Spacing.marginMobile, Spacing.sm),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(RadiusTokens.full),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(RadiusTokens.full),
                border: const Border(
                  top: BorderSide(color: AppColors.glassBorder),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: List.generate(_destinations.length, (i) {
                  final isActive = i == index;
                  final isCreate = i == 2;
                  final dest = _destinations[i];

                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        if (i == index) {
                          ref.read(scrollToTopProvider.notifier).state++;
                        }
                        widget.navigationShell.goBranch(i, initialLocation: i == index);
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isCreate)
                            Container(
                              width: 48,
                              height: 48,
                              decoration: const BoxDecoration(
                                color: AppColors.tertiary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.add_circle,
                                size: IconSizes.xl,
                                color: AppColors.onTertiary,
                              ),
                            )
                          else
                            Icon(
                              dest.icon,
                              size: IconSizes.md,
                              color: isActive ? AppColors.tertiary : AppColors.inkMuted,
                            ),
                          if (!isCreate) ...[
                            const SizedBox(height: 3),
                            Text(
                              dest.label,
                              style: TextStyle(
                                fontSize: FontSizes.labelSm,
                                fontWeight: isActive ? FontWeights.semiBold : FontWeights.regular,
                                color: isActive ? AppColors.tertiary : AppColors.inkMuted,
                                letterSpacing: LetterSpacing.label,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify compilation**

Run: `dart analyze lib/screens/tabs/tab_layout.dart`
Expected: No errors (may warn about removed _PostFabSheet — that's fine, it's moving to create_post_screen.dart)

- [ ] **Step 3: Commit**

```bash
git add lib/screens/tabs/tab_layout.dart
git commit -m "feat(P3): rewrite TabLayout with 5-tab glass bottom bar, gold Create button"
```

### Task 3.2: Update app_router.dart for 5 tabs

**Files:**
- Modify: `lib/router/app_router.dart`

- [ ] **Step 1: Add 5th branch and Create Post route**

In `app_router.dart`, change the StatefulShellRoute branches from 4 to 5 by adding a branch between branch 2 (currently /chat) and branch 3 (currently /identity):

In the branches list, after the ChatListScreen branch (index 2), insert:

```dart
StatefulShellBranch(
  routes: [
    GoRoute(
      path: '/create-post',
      builder: (context, state) => const CreatePostScreen(),
    ),
  ],
),
```

And update the import at the top:

```dart
import '../screens/tabs/create_post_screen.dart';
```

- [ ] **Step 2: Verify the router compiles**

Run: `dart analyze lib/router/app_router.dart`
Expected: Error about missing CreatePostScreen — that's expected, created in next task

- [ ] **Step 3: Commit (together with Task 3.3)**

### Task 3.3: Create create_post_screen.dart

**Files:**
- Create: `lib/screens/tabs/create_post_screen.dart`

- [ ] **Step 1: Write CreatePostScreen**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/colors.dart';
import '../../theme/design_system.dart';
import '../../widgets/core/glass_panel.dart';
import '../../widgets/core/ghost_input.dart';
import '../../state/world_provider.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _isSovereignAnnouncement = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final worlds = ref.watch(worldProvider).worlds.values.toList();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.surface.withValues(alpha: 0.8),
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.inkSecondary),
          onPressed: () => context.go('/'),
        ),
        title: Text(
          'Vertiege',
          style: TextStyle(
            fontFamily: AppFont.headline,
            fontSize: FontSizes.headlineLg,
            fontWeight: FontWeights.bold,
            color: AppColors.tertiary,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: Spacing.md),
            child: FilledButton(
              onPressed: () {
                // Post publishing handled in future task
                context.go('/');
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.tertiary,
                foregroundColor: AppColors.onTertiary,
              ),
              child: const Text('PUBLISH'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Spacing.marginMobile),
        child: Column(
          children: [
            const SizedBox(height: Spacing.xl),

            // World selector
            if (worlds.isNotEmpty)
              GlassPanel(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.md),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.secondaryContainer,
                        borderRadius: BorderRadius.circular(RadiusTokens.md),
                      ),
                      child: const Icon(Icons.language, color: AppColors.tertiary, size: IconSizes.sm),
                    ),
                    const SizedBox(width: Spacing.md),
                    Expanded(
                      child: Text(
                        worlds.first.name,
                        style: const TextStyle(
                          fontSize: FontSizes.headlineMd,
                          fontWeight: FontWeights.semiBold,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    const Icon(Icons.expand_more, color: AppColors.inkSecondary),
                  ],
                ),
              ),

            const SizedBox(height: Spacing.lg),

            // Sovereign Announcement toggle
            GlassPanel(
              padding: const EdgeInsets.all(Spacing.lg),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.tertiary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(RadiusTokens.md),
                    ),
                    child: const Icon(Icons.stars, color: AppColors.tertiary, size: IconSizes.lg),
                  ),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sovereign Announcement',
                          style: TextStyle(
                            fontSize: FontSizes.headlineMd,
                            fontWeight: FontWeights.semiBold,
                            color: AppColors.tertiary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Pin to the priority feed of all members.',
                          style: TextStyle(
                            fontSize: FontSizes.bodyMd,
                            color: AppColors.inkSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isSovereignAnnouncement,
                    onChanged: (v) => setState(() => _isSovereignAnnouncement = v),
                    activeColor: AppColors.tertiary,
                    activeTrackColor: AppColors.tertiary.withValues(alpha: 0.4),
                  ),
                ],
              ),
            ),

            const SizedBox(height: Spacing.lg),

            // Editor
            GlassPanel(
              padding: const EdgeInsets.all(Spacing.xl),
              child: Column(
                children: [
                  GhostInput(
                    controller: _titleController,
                    hint: 'Title of your dispatch...',
                  ),
                  const SizedBox(height: Spacing.lg),
                  GhostInput(
                    controller: _bodyController,
                    hint: 'Share your insights with the Nexus...',
                    maxLines: 8,
                  ),
                ],
              ),
            ),

            const SizedBox(height: Spacing.lg),

            // Quick attach bar
            Row(
              children: [
                _AttachChip(icon: Icons.image, label: 'UPLOAD IMAGE'),
                const SizedBox(width: Spacing.sm),
                _AttachChip(icon: Icons.description, label: 'DOCUMENT'),
                const SizedBox(width: Spacing.sm),
                _AttachChip(icon: Icons.link, label: 'ADD LINK'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AttachChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _AttachChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.sm + 2),
      decoration: BoxDecoration(
        color: AppColors.glassBackground,
        borderRadius: BorderRadius.circular(RadiusTokens.full),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: IconSizes.sm, color: AppColors.inkSecondary),
          const SizedBox(width: Spacing.sm),
          Text(
            label,
            style: const TextStyle(
              fontSize: FontSizes.labelSm,
              fontWeight: FontWeights.semiBold,
              color: AppColors.inkSecondary,
              letterSpacing: LetterSpacing.label,
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Commit router + create post screen together**

```bash
git add lib/router/app_router.dart lib/screens/tabs/create_post_screen.dart
git commit -m "feat(P3): add 5th tab (Create Post) with glass composer, update router"
```

---

## Phase 4: Tab Screens

### Task 4.1: Rewrite nexus_screen.dart

**Files:**
- Modify: `lib/screens/tabs/nexus_screen.dart`

Rewrite as a Sovereign-style activity feed with:
- Hero section "Nexus Activity" in Space Grotesk headline-lg
- Glass panel cards for each activity item (profile avatar + content + relative time + indicator dot)
- Standing Updates section with glow-tertiary on rep changes
- World Invites section with glass cards, banner image, tier labels, Accept/Decline buttons
- Keep Riverpod integration but replace all visual styling
- Remove QuestBanner, StoryRow, old tab chips — replace with Stitch sections

Key code pattern (feed item):

```dart
Widget _buildActivityItem(String name, String action, String? subtitle, IconData icon, Color accent, Widget? trailing) {
  return GlassPanel(
    padding: const EdgeInsets.all(Spacing.lg),
    child: Row(
      children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(RadiusTokens.md),
          ),
          child: Icon(icon, color: accent, size: IconSizes.lg),
        ),
        const SizedBox(width: Spacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: FontSizes.bodyMd, fontWeight: FontWeights.regular, color: AppColors.ink),
                  children: [
                    TextSpan(text: name, style: TextStyle(fontWeight: FontWeights.semiBold, color: accent)),
                    const TextSpan(text: ' $action'),
                  ],
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(fontSize: FontSizes.labelSm, color: AppColors.inkMuted)),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    ),
  );
}
```

- [ ] **Step 1: Commit**

```bash
git add lib/screens/tabs/nexus_screen.dart
git commit -m "feat(P4): rebuild Nexus screen with glass activity feed, tier updates, world invites"
```

### Task 4.2: Rewrite explore_screen.dart

**Files:**
- Modify: `lib/screens/tabs/explore_screen.dart`

Rewrite as the World Showcase Index:
- Header: "Discovery of Worlds" in Space Grotesk headline-lg
- Grid/Tier View toggle (glass segment control)
- Bento grid of tiered world cards:
  - Apex (Tier I): Large hero card with gold glow, image background, "INVITE ONLY", reputation minimum
  - Elite (Tier II): Medium card with violet glow, member count, profession tags
  - Hustler (Tier III): Card with orange glow, growth bar, "HUSTLER HUB" badge
- Search bar: ghost input style
- Bottom: "Explore More Realms" with chevron
- Remove old filter pills, featured horizontal row, section headers

- [ ] **Step 1: Commit**

```bash
git add lib/screens/tabs/explore_screen.dart
git commit -m "feat(P4): rebuild Explore screen with bento grid, tiered world cards, grid/tier toggle"
```

### Task 4.3: Rewrite identity_screen.dart

**Files:**
- Modify: `lib/screens/tabs/identity_screen.dart`

Rewrite as the Sovereign Identity profile:
- Large avatar (160px) with gold gradient ring + glow background
- REP badge pill below avatar
- "Sovereign User" name + tier title
- "ESTABLISH DOMINION" + "MESSAGES" buttons
- Standing section: tier progress bars (Apex/Elite/Hustler) with % filled
- Stats: Total Points (large number), Tier insignia, +/- cycle %
- Achievements bento grid (reuse AchievementCard with glass style)
- Keep Riverpod integration (residentProvider)

- [ ] **Step 1: Commit**

```bash
git add lib/screens/tabs/identity_screen.dart
git commit -m "feat(P4): rebuild Identity screen with sovereign avatar, tier standing, glass achievements"
```

### Task 4.4: Rewrite chat_list_screen.dart

**Files:**
- Modify: `lib/screens/tabs/chat_list_screen.dart`

Update to glass conversation list:
- Glass panel list items with avatar, preview text, timestamp, unread count
- Online status dot on avatar
- Glass container wrapping the entire list
- Keep Riverpod chat provider integration

- [ ] **Step 1: Commit**

```bash
git add lib/screens/tabs/chat_list_screen.dart
git commit -m "feat(P4): rebuild Chat List with glass conversation items"
```

### Task 4.5: Rewrite alerts_screen.dart

**Files:**
- Modify: `lib/screens/tabs/alerts_screen.dart`

Update to Sovereign notifications:
- Glass panels for notification items
- Grouped by "Today" / "This Week" with sticky headers
- Notification icon in colored container (color by type)
- Swipe actions preserved

- [ ] **Step 1: Commit**

```bash
git add lib/screens/tabs/alerts_screen.dart
git commit -m "feat(P4): rebuild Alerts screen with glass notification cards"
```

---

## Phase 5: World Screens

### Task 5.1: Rewrite world_detail_screen.dart

**Files:**
- Modify: `lib/screens/world_detail_screen.dart`

Rebuild as a dynamic world hub with tier-specific theming:
- Full-bleed hero image (400px) with gradient overlay (black → transparent)
- Tier badge overlay (Apex gold / Elite violet / Hustler orange)
- "Active Channel: [world name]" label
- World description in body-lg
- Action buttons: "Launch Stream" / "Protocol Docs" (Hustler), "Request Entry" (Apex)
- Bento grid layout for:
  - Leaderboard (leaderboard widget, live indicator)
  - Chat panel (glass, with live messages, chat input)
  - Resource vault (file list with download icons)
  - Global pressure bar
- Tier-specific accent color (from world type)
- Keep all Riverpod providers for world/channel/event data

- [ ] **Step 1: Commit**

```bash
git add lib/screens/world_detail_screen.dart
git commit -m "feat(P5): rebuild World Detail with hero image, bento grid, tier theming"
```

### Task 5.2: Rewrite world_channel_screen.dart

**Files:**
- Modify: `lib/screens/world_channel_screen.dart`

Update to Sovereign chat bubbles:
- Received: glass panel, rounded 8px with 3px bottom-left
- Sent: primary background, rounded 8px with 3px bottom-right
- Timestamps in label-sm, muted
- Chat input: glass, bottom border hustler-orange on focus
- System messages: hustler/10 background with left border
- Keep Supabase realtime integration

- [ ] **Step 1: Commit**

```bash
git add lib/screens/world_channel_screen.dart
git commit -m "feat(P5): rebuild World Channel with Sovereign glass chat bubbles"
```

### Task 5.3: Rewrite world_settings_screen.dart

**Files:**
- Modify: `lib/screens/world_settings_screen.dart`

Update to glass admin panel:
- Side nav (desktop) with world icon, active gold left-border
- Ghost inputs for name/description
- Glass panels for settings sections
- "PUBLISH CHANGES" gold button
- Keep existing functionality (channel CRUD, member management, invites)

- [ ] **Step 1: Commit**

```bash
git add lib/screens/world_settings_screen.dart
git commit -m "feat(P5): rebuild World Settings with glass panels, ghost inputs, side nav"
```

### Task 5.4: Rewrite world_members_screen.dart

**Files:**
- Modify: `lib/screens/world_members_screen.dart`

Update styling: glass list items, sovereign badge for owner, tier-colored rep display.

- [ ] **Step 1: Commit**

```bash
git add lib/screens/world_members_screen.dart
git commit -m "feat(P5): rebuild World Members with glass list styling"
```

---

## Phase 6: Widget Migration

### Task 6.1: Migrate world widgets

**Files:**
- Modify: `lib/widgets/worlds/world_card.dart` — Replace with SovereignCard-based tiered card
- Modify: `lib/widgets/worlds/world_hero_banner.dart` — Full-bleed with gradient overlay + tier badge
- Modify: `lib/widgets/worlds/world_banner.dart` — Use glass panel
- Modify: `lib/widgets/worlds/world_icon.dart` — 64px circle with 4px canvas border ring
- Modify: `lib/widgets/worlds/world_info_sheet.dart` — Glass panel
- Modify: `lib/widgets/worlds/world_member_row.dart` — Glass with gold border
- Modify: `lib/widgets/worlds/world_residents.dart` — Glass list
- Modify: `lib/widgets/worlds/world_events_card.dart` — Glass + glow
- Modify: `lib/widgets/worlds/leaderboard.dart` — Glass panel, hustler accent
- Modify: `lib/widgets/worlds/access_icon.dart` — Use gold lock icon
- Modify: `lib/widgets/worlds/world_access_guard.dart` — Glass overlay

For each, replace `AppColors.surface` → `AppColors.glassBackground`, `AppColors.borderDefault` → `AppColors.glassBorder`, wrap in GlassPanel. Remove old shadows. Replace AppColors.accentPrimary → AppColors.primary.

- [ ] **Step 1: Commit world widgets**

```bash
git add lib/widgets/worlds/
git commit -m "feat(P6): migrate all world widgets to glass/glow Sovereign styling"
```

### Task 6.2: Migrate feed widgets

**Files:**
- Modify: `lib/widgets/feed/post_item.dart` — Glass panel, avatar circle, gold name, muted timestamp
- Modify: `lib/widgets/feed/post_composer.dart` — Glass editor, ghost inputs
- Modify: `lib/widgets/feed/post_input.dart` — Glass panel with ghost input
- Modify: `lib/widgets/feed/comment_sheet.dart` — Glass bottom sheet
- Modify: `lib/widgets/feed/reaction_bar.dart` — Glass chip reactions
- Modify: `lib/widgets/feed/media_grid.dart` — Glass container
- Modify: `lib/widgets/feed/post_image.dart` — Glass border

- [ ] **Step 1: Commit feed widgets**

```bash
git add lib/widgets/feed/
git commit -m "feat(P6): migrate all feed widgets to glass Sovereign styling"
```

### Task 6.3: Migrate profile widgets

**Files:**
- Modify: `lib/widgets/profile/badge_display.dart` — Glass + glow, grid layout
- Modify: `lib/widgets/profile/cosmetic_avatar.dart` — 160px with gold gradient ring
- Modify: `lib/widgets/profile/name_banner.dart` — Space Grotesk headline
- Modify: `lib/widgets/profile/badge.dart` — Glass chip
- Modify: `lib/widgets/profile/share_card.dart` — Glass card

- [ ] **Step 1: Commit profile widgets**

```bash
git add lib/widgets/profile/
git commit -m "feat(P6): migrate profile widgets to glass + gold Sovereign styling"
```

### Task 6.4: Migrate achievement widgets

**Files:**
- Modify: `lib/widgets/achievements/achievement_card.dart` — Glass + glow, achievement-glow-tertiary for gold tier, progress bar
- Modify: `lib/widgets/achievements/achievement_grid.dart` — Bento grid
- Modify: `lib/widgets/achievements/tier_celebration.dart` — Celebration glow

- [ ] **Step 1: Commit achievement widgets**

```bash
git add lib/widgets/achievements/
git commit -m "feat(P6): migrate achievement widgets to glass bento + glow"
```

### Task 6.5: Migrate core widgets

**Files:**
- Modify: `lib/widgets/core/empty_state.dart` — Glass + dashed border, muted icon
- Modify: `lib/widgets/core/fade_in.dart` — No visual change (animation wrapper)
- Modify: `lib/widgets/core/screen_loading.dart` — Replace with GlassLoadingList
- Modify: `lib/widgets/core/notification_bell.dart` — Gold icon with achievement pink badge
- Modify: `lib/widgets/core/themed_text.dart` — Use new type scale
- Modify: `lib/widgets/core/screen_header.dart` — Space Grotesk, gold accent
- Modify: `lib/widgets/core/status_dot.dart` — Glass container
- Modify: `lib/widgets/core/xp_toast.dart` — Glass toast with glow

- [ ] **Step 1: Commit core widgets**

```bash
git add lib/widgets/core/
git commit -m "feat(P6): migrate core widgets to Sovereign styling"
```

### Task 6.6: Migrate remaining screens

**Files:**
- Modify: `lib/screens/chat_room_screen.dart` — Sovereign chat bubbles, glass input
- Modify: `lib/screens/resident_profile_screen.dart` — Glass profile card
- Modify: `lib/screens/settings_screen.dart` — Glass list tiles
- Modify: `lib/screens/search_screen.dart` — Ghost search input, glass results
- Modify: `lib/screens/create_world_screen.dart` — Glass form, ghost inputs
- Modify: `lib/screens/achievements/achievements_index.dart` — Bento grid
- Modify: `lib/screens/achievements/achievement_category.dart` — Glass list
- Modify: `lib/screens/splash_screen.dart` — Gold branding on obsidian
- Modify: `lib/screens/auth/login_screen.dart` — Glass form, gold CTA
- Modify: `lib/screens/auth/signup_screen.dart` — Glass form, gold CTA
- Modify: `lib/screens/onboarding/onboarding_screen.dart` — Glass panels

For each screen: replace color references, swap Card → GlassPanel, replace TextField → GhostInput, change AppColors.accentPrimary → AppColors.primary, AppColors.surface → AppColors.canvas for backgrounds. Keep all business logic, navigation, and providers intact.

- [ ] **Step 1: Commit remaining screens**

```bash
git add lib/screens/chat_room_screen.dart lib/screens/resident_profile_screen.dart lib/screens/settings_screen.dart lib/screens/search_screen.dart lib/screens/create_world_screen.dart lib/screens/achievements/ lib/screens/splash_screen.dart lib/screens/auth/ lib/screens/onboarding/
git commit -m "feat(P6): migrate all remaining screens to Sovereign glass/glow design"
```

---

## Phase 7: Polish

### Task 7.1: Add world state variants (Loading/Error/Empty)

**Files:**
- Modify: `lib/screens/world_detail_screen.dart`

Add state handling that matches the Stitch Forge variants:
- Loading: Glass panels with Pulse animation, shimmer leaderboard, shimmer chat
- Error: SovereignErrorBanner at top, "Handshake Interrupted" card with sync retry button, degraded widgets with pulse placeholders, protocol log section
- Empty: Dashed-border glass panels with "add_circle" placeholders, "No data available" muted text

- [ ] **Step 1: Implement states**

In `world_detail_screen.dart`, wrap the body in a `switch(worldState)` that renders the appropriate state variant.

- [ ] **Step 2: Commit**

```bash
git add lib/screens/world_detail_screen.dart
git commit -m "feat(P7): add Loading/Error/Empty world states matching Stitch variants"
```

### Task 7.2: Apply state variants to all screens

**Files:**
- Modify: Each screen in `lib/screens/`

Replace any remaining `CircularProgressIndicator` instances with `GlassLoadingCard`/`GlassLoadingList`. Replace error widgets with `SovereignErrorBanner`. Replace empty widgets with `GlassPanel` + dashed border + muted text.

- [ ] **Step 1: Commit**

```bash
git add lib/screens/
git commit -m "feat(P7): apply Sovereign loading/error/empty states across all screens"
```

### Task 7.3: Final cleanup and verify

- [ ] **Step 1: Run dart analyze**

```bash
dart analyze lib/
```

Fix any remaining issues from old color/type references.

- [ ] **Step 2: Verify all imports resolve**

```bash
dart analyze lib/ --fatal-infos
```

Expected: Clean, or only pre-existing warnings.

- [ ] **Step 3: Remove legacy color aliases (optional)**

If `dart analyze` confirms no remaining uses of legacy aliases, remove the "Legacy aliases" section from `lib/theme/colors.dart`.

- [ ] **Step 4: Final commit**

```bash
git add -A
git commit -m "feat(P7): final cleanup — remove legacy references, verify compilation"
```

---

## Verification Checklist

After all phases complete:
- [ ] `dart analyze lib/` passes with no errors
- [ ] App launches without theme-related crashes
- [ ] All 5 bottom tabs navigate correctly
- [ ] Create Post screen opens with glass editor
- [ ] World cards display with tier-appropriate glow
- [ ] Nexus feed shows glass activity items
- [ ] Profile shows sovereign avatar with gold ring
- [ ] Chat bubbles use correct Sovereign styling
- [ ] Loading states show pulse instead of shimmer
- [ ] Error states show banner with retry
- [ ] Empty states show dashed glass panels

---

## Source: `docs/archive/plan-PERFECTION-BACKLOG.md`

# Moved

This document lives at **[planning/perfection-backlog.md](planning/perfection-backlog.md)** (archived).

---

## Source: `docs/archive/plans/2026-05-19-long-horizon-product-completion-plan.md`

# Vertiege Long-Horizon Product Completion Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` or `superpowers:executing-plans` task-by-task. The implementing agent may not have image-reading capability. If a task requires visual inspection of screenshots, generated assets, UI captures, image quality, placeholder quality, contrast from screenshots, or banner/icon evaluation, write a clear note in the milestone report for Codex to perform the visual review.

**Goal:** Turn Vertiege from a working stabilization APK into a polished, reliable, production-grade social world app with consistent Forui UI, persistent Supabase-backed data, Firebase infrastructure, fast loading, complete world content, and a clear feature roadmap.

**Architecture:** Supabase remains source of truth for app data, auth, storage, realtime, RLS, and domain state. Firebase is infrastructure-only for Crashlytics, Analytics, Remote Config, and FCM. Flutter uses Forui-led app primitives, repository-backed state, cache-first loading, durable outbox mutations, and explicit error/loading/sync states.

**Tech Stack:** Flutter/Dart, Riverpod, go_router, Forui, Supabase Postgres/RLS/Realtime/Storage/Edge Functions, Firebase Core/Messaging/Crashlytics/Analytics/Remote Config, Android JDK 21, GitHub Actions.

---

## Non-Negotiable Agent Reporting Rule

Maintain an implementation report after each milestone with completed tasks, files changed, test results, unresolved risks, screenshots or APK paths if produced, and Codex visual-review requests for anything requiring image/UI inspection.

Use this exact marker:

```markdown
## Codex Visual Review Needed
- Screen/asset:
- Why visual inspection is needed:
- How to reproduce/open it:
- Related files:
```

Do not claim visual quality is fixed purely from code inspection when the issue depends on rendered screenshots or images.

---

## Phase 0: Baseline And Merge

**Goal:** Accept the stabilization branch as the new baseline, then stop treating old plans as active truth.

**Required Actions**
- Merge `feat/stabilization-plan` into `main` after confirming Nexus feed recursion is gone, world channels show, FAB behavior is accepted, APK builds and installs, and `flutter test` passes.
- Delete or archive stale feature branches only after confirming their commits are merged or obsolete.
- Keep `REPORT.md` as historical reference.
- Make this `PLAN.md` the active working plan.
- Update `README.md`, `docs/DESIGN.md`, and `docs/PROGRESS.md` because they still describe older dark/glass direction.

**Acceptance**
- `main` contains stabilization work.
- Root `PLAN.md` contains this roadmap or a task-sliced version of it.
- No active docs describe glass-first/dark-first UI as current product direction.

---

## Phase 1: Immediate Installed-App Polish

**Goal:** Fix the issues still visible in the installed APK before starting deeper architecture work.

**Key Fixes**
- Redesign Chat > Worlds so the world rail shows both icon/image and readable name.
- Replace overcrowded world detail tabs with `Feed`, `Channels`, `Residents`, `More`.
- Move secondary world tools into `More`.
- Verify create-world flow on device and capture exact error if it fails.
- Separate `Foundation` lore from `Guide` action shortcuts.
- Replace missing/noisy empty states with minimal Forui-style states.

**Visual Review Note**
- Ask Codex to review screenshots for world rail readability, tab overflow, placeholder image quality, banner image distortion, and light/dark contrast.

**Acceptance**
- User can identify worlds by name in Chat.
- No world page has clipped tab labels.
- Create world succeeds or reports a precise actionable error.
- Empty states look intentional after Codex visual review.

---

## Phase 2: Product Source Of Truth Cleanup

**Goal:** Make the app vision, docs, and implementation agree.

**Update**
- `README.md`
- `docs/DESIGN.md`
- `docs/PROGRESS.md`
- `PLAN.md`
- `docs/audits/product-gap-audit.md`

**Product Definition**
- Vertiege is a social world/community app, not a financial app.
- Worlds are identity-rich communities with channels, residents, lore, posts, polls, quests, events, achievements, and economy features where relevant.
- Default worlds must feel independent.
- Immabe remains admin/testing superuser with all-world access.

**Acceptance**
- New agent can understand the current product from docs.
- Historical glass/dark-first design language is removed or explicitly marked historical.

---

## Phase 3: Forui Design System Completion

**Goal:** Finish the UI migration so every screen feels like one app.

**Design Rules**
- Light theme: white/minimal surfaces, dark readable text, compact spacing.
- Dark theme: AMOLED black, high-contrast text, restrained borders.
- Accent colors only for selected state, semantic status, world identity, rarity, or destructive/success/warning states.
- Avoid heavy gradients, blur panels, and white text over uncontrolled images.
- Use subtle scrims only when text overlays images.

**Implementation**
- Standardize app primitives: `VScaffold`, `VTopBar`, `VBottomNav`, `VCard`, `VListTile`, `VButton`, `VEmptyState`, `VLoadingState`, `VErrorState`, `VImage`, `VWorldBadge`, and `VSyncStatusBadge`.
- Replace legacy patterns: `GlassPanel`, `GlassSheet`, `SovereignCard`, screen-level `GoogleFonts`, arbitrary `Colors.*`, unreviewed `LinearGradient`, and unreviewed `BackdropFilter`.
- Keep documented exceptions only for image viewers, export/share visuals, readable image scrims, and generated media previews.

**Acceptance**
- Legacy UI searches only return documented exceptions.
- No low-contrast text, clipped labels, oversized card headings, or mismatched plain widgets after Codex visual review.

---

## Phase 4: Navigation And Information Architecture

**Goal:** Make the app easier to understand and faster to move through.

**Navigation Model**
- Bottom tabs: `Nexus`, `Discover`, `Chat`, `Identity`, `More`.
- Chat owns DMs, world channels, unread counts, and active residents.
- World detail owns overview, feed, channels shortcut, residents, and secondary modules through `More`.
- Composer appears only from valid feed/channel contexts.

**Deep Links**
- Add routes for post detail, world detail, channel, profile, notification target, and auth callback.
- Replace placeholder auth callback handling with real session handling.

**Acceptance**
- New user can find worlds, join/enter channels, create a post, and return home without confusion.
- Route restoration works after restart or notification tap.

---

## Phase 5: World Content, Identity, And Media System

**Goal:** Make every world feel distinct and remove placeholder-looking content.

**World Requirements**
- Every world has name, slug, description, lore, banner, icon, accent, category, tags, default channels, and starter content.
- Starter worlds remain `neon-district` and `crystal-shore`.
- Immabe can access every world regardless of tier or visibility.

**Channels**
- Every default world gets `info`, `rules`, `roles`, and `general`.
- Channel text must be world-specific and include safety disclaimers for medical, financial, legal, and technical-risk worlds.

**Media Pipeline**
- Standardize all images through `VImage`.
- Fallback order: Supabase image, bundled generated asset, category placeholder, minimal icon empty state.
- Compress large assets.
- Add or verify storage buckets for avatars, world banners, icons, post media, marketplace media, and verification evidence.

**Acceptance**
- No world uses generic placeholder visuals unless intentionally unconfigured.
- Chat world navigation shows recognizable icon and name.
- Missing images degrade gracefully.

---

## Phase 6: Supabase Reliability And Migration Hygiene

**Goal:** Ensure the backend can be trusted across fresh projects and the existing remote project.

**Work**
- Do not rewrite applied migrations.
- Add corrective migrations for remote issues.
- Quarantine faulty unapplied migrations.
- Audit RLS for worlds, memberships, channels, messages, posts, comments, reactions, bookmarks, polls, quests, events, notifications, marketplace, treasury, achievements, device tokens, and storage.
- Eliminate recursive policy patterns.
- Use security-definer helpers with fixed `search_path`.
- Add or verify RPCs for join world, create world, post actions, comments, reactions, bookmarks, poll votes, channel reads/messages, marketplace, treasury, and quest progress.
- Add indexes for feed, comments, reactions, bookmarks, memberships, channel messages, notifications, search, and marketplace filters.

**Acceptance**
- Fresh Supabase project can run all migrations once.
- Existing remote project can apply new migrations without reset.
- Allowed reads work; denied private rows remain denied.
- Immabe superuser can read/admin all worlds.

---

## Phase 7: Persistence, Repositories, And Outbox

**Goal:** Stop features from pretending to work locally when they are not durable.

**Repository Standard**
- Add or complete repositories for profile, worlds, posts, chat, notifications, achievements, quests, events, polls, marketplace, treasury, alliances, and cosmetics.
- Providers must call repositories, not write authoritative state directly to `SharedPreferences`.

**State Types**
- Standardize `RepositoryResult<T>`, `LoadState<T>`, `AppFailure`, `SyncStatus`, `MutationOutboxItem`, `RetryPolicy`, and `ConflictResolution`.

**Outbox**
- Unify deprecated offline queue and mutation outbox.
- Durable actions: post, comment, reaction, bookmark, poll vote, join world, create world, channel message, marketplace action, treasury action, quest progress.
- Failed mutations show visible retry/failure state.

**Acceptance**
- Refresh/restart does not lose user actions.
- Missing Supabase/auth does not return fake success.
- Offline actions reconcile when connectivity returns.

---

## Phase 8: Performance And Loading Speed

**Goal:** Make the app feel fast without hiding backend failures.

**Startup**
- Remove fixed splash delays.
- Show shell quickly.
- Load resident/world/feed first.
- Lazy-load achievements, events, quests, store, notifications.
- Register push tokens after resident becomes available.

**Loading**
- Add pagination for feed, comments, channel messages, notifications, marketplace, and residents.
- Use cache-first display, server refresh, and realtime updates.
- Batch queries and avoid duplicate provider loads.

**Images**
- Use thumbnails in lists.
- Precache visible world icons/banners.
- Compress oversized bundled images.
- Avoid full banners in small rail/list cells.

**Instrumentation**
- Trace startup, first feed load, world list load, channel load, create post, create world, and notification open.

**Acceptance**
- App shell appears quickly.
- Nexus and Chat show skeletons instead of blank stalls.
- Large images do not cause jank.

---

## Phase 9: Firebase Infrastructure Completion

**Goal:** Make Firebase useful without moving app data out of Supabase.

**Crashlytics**
- Replace console-only reporter with Firebase Crashlytics.
- Record Flutter/platform/repository/Supabase/outbox failures.
- Attach only non-PII context.

**Analytics**
- Track onboarding, world viewed/joined/created, channel opened, post/comment/reaction/bookmark, notification opened, marketplace action, quest action, surfaced errors, and outbox failures.
- Do not log message body, post body, email, or sensitive content.

**Remote Config**
- Add feature flags and defaults for marketplace, treasury, quests, events, page sizes, startup load limit, verbose errors, minimum build, and maintenance banner.

**FCM**
- Handle token registration, token refresh, foreground notifications, background/opened notifications, and notification deep-link routing.
- Use Supabase Edge Functions for fanout.

**Acceptance**
- Crash test appears in Crashlytics.
- Notification tap opens the right route.
- Remote Config can disable a feature without app release.

---

## Phase 10: Feature Completion Roadmap

**Goal:** Close the gap between app vision and visible product.

**Major Areas**
- Nexus/feed: unified composer, media, post detail, comments, reactions, bookmarks, edit/delete/pin, filters, report/hide/mute.
- Worlds: creation, settings, roles, permissions, invites, resident list, moderation, analytics.
- Chat: persistent messages, unread badges, last-read marker, edit/delete, attachments, mentions.
- Quests/events/challenges: definitions, progress, RSVP, reminders, rewards.
- Marketplace/treasury: listings, media, transactions, ledger, admin audit.
- Cosmetics/achievements: inventory, unlock/equip, progress, rarity styles.
- Governance/polls: creation, voting, results, eligibility, realtime updates.
- Search/discovery: worlds, posts, residents, channels, tags, recommendations.
- Identity: edit profile, avatar upload, verification, account export/delete, privacy.
- Admin/moderation: reports queue, takedown, suspension, audit log, real moderation pipeline.

**Acceptance**
- No visible "coming soon" unless feature-flagged off.
- Every visible button works, explains unavailable state, or is hidden.
- Feature data persists through restart.

---

## Phase 11: Security, Privacy, And Abuse Prevention

**Goal:** Avoid shipping a social app with weak access control or unsafe content handling.

**Work**
- RLS tests for every table.
- Storage bucket policy tests.
- Superuser access scoped and auditable.
- No service-role key in Flutter app.
- Rate limits for post, world, message, reaction, report, invite flows.
- Edge Functions verify JWT and permissions.
- Account deletion/export.
- Block/mute/report.
- No PII in analytics/crash logs.
- World-specific safety rules for medical, financial, legal, and exploit-risk content.

**Acceptance**
- RLS denial cases are tested.
- Abuse-prone flows have limits and report paths.
- Sensitive text is not sent to analytics.

---

## Phase 12: Accessibility, Mobile Quality, And Internationalization

**Goal:** Make the app usable on real phones, not just ideal screenshots.

**Work**
- Test text scale at 1.0, 1.3, and 1.6.
- Minimum tap target 44x44 where practical.
- Semantic labels for icon-only buttons.
- Contrast checks in light and AMOLED dark.
- Reduced motion support.
- Keyboard avoidance for composer, comments, chat, auth, and create world.
- Safe areas on every screen.
- Pull-to-refresh where expected.
- Extract user-facing strings.

**Acceptance**
- No major screen breaks with larger text.
- Keyboard does not cover submit buttons.
- Icon-only controls have semantics/tooltips.

---

## Phase 13: Testing, CI, And Release Discipline

**Goal:** Make future agents prove changes before producing APKs.

**Test Layers**
- Unit tests for models, repositories, outbox, sync status, remote config defaults.
- Provider tests for cache-first load, refresh, error, retry.
- Supabase tests for RLS and RPC behavior.
- Widget/golden tests for Nexus, Chat > Worlds, World Detail, Channel, Identity, Composer, Empty/Error states.
- Integration tests for onboarding, join world, create post, send message, create world, restart persistence.
- Performance tests for startup, feed load, channel load, image-heavy screens.

**CI**
- Analyze.
- Test.
- Migration validation.
- Android release APK build with JDK 21.
- Upload APK artifact.
- Optional Firebase App Distribution after secrets are configured.

**Required Commands**

```powershell
$env:JAVA_HOME="C:\Users\Immabe\AppData\Local\jdk-21.0.9+10"
flutter pub get
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test
flutter build apk --release
```

**Acceptance**
- CI can build APK without local machine intervention.
- Release APK is attached as artifact.
- No branch merges without green checks unless explicitly overridden.

---

## Public Interfaces And Types To Add Or Standardize

**Flutter**
- `RepositoryResult<T>`
- `LoadState<T>`
- `AppFailure`
- `SyncStatus`
- `MutationOutboxItem`
- `WorldNavigationSummary`
- `WorldMedia`
- `MediaAssetRef`
- `VImageSource`
- `NotificationPayload`
- `AnalyticsEvent`
- `RemoteConfigKeys`
- `PerformanceTraceName`

**Supabase**
- Stable RPCs for core mutations.
- `device_tokens` token refresh support.
- Storage buckets and policies for media.
- World icon/banner fields.
- Channel foundation/starter content fields.
- Audit log table for admin/moderation actions.

**UI**
- One canonical composer.
- One canonical empty state.
- One canonical image widget.
- One canonical world list/rail item.
- One canonical error surface.

---

## Milestone Order

1. Merge stabilization baseline.
2. Fix installed-app polish: world names, tab overflow, create-world verification.
3. Rewrite source-of-truth docs.
4. Finish Forui UI migration.
5. Complete media/world identity system.
6. Harden Supabase/RLS/RPC/migrations.
7. Standardize repositories and durable outbox.
8. Improve startup/loading/realtime/image performance.
9. Complete Firebase infrastructure.
10. Fill feature gaps.
11. Harden security/privacy/accessibility.
12. Build CI-backed release process.

---

## Assumptions

- The stabilization APK is good enough to merge, but not production quality.
- `feat/stabilization-plan` is the accepted baseline branch.
- Supabase remains the source of truth for app data and auth.
- Firebase remains infrastructure-only.
- Immabe / `ltyl.naughty@gmail.com` remains superuser with all-world access.
- Light theme is the default.
- Dark theme should be AMOLED black.
- DeepSeek v4 Pro can implement code and run tests, but Codex must handle visual/image-based review.
- Work should proceed in milestones, not one giant change.

---

## Source: `docs/archive/plans/2026-05-20-firebase-supabase-hybrid-completion-plan.md`

# Firebase + Supabase Hybrid Completion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Complete Vertiege's Firebase infrastructure and Supabase integration so push notifications, background notification routing, Google login, storage buckets, notification fanout, Crashlytics, Analytics, Remote Config, App Check, and release verification work as one reliable hybrid system.

**Architecture:** Supabase remains the source of truth for auth, profiles, worlds, posts, chat, notifications, storage metadata, RLS, realtime, and domain data. Firebase is infrastructure-only: FCM, Crashlytics, Analytics, Remote Config, Performance Monitoring, and App Check. Flutter should initialize Firebase safely, register push tokens only after a Supabase resident exists, store tokens in Supabase, and use Supabase Edge Functions to fan out notifications through Firebase Cloud Messaging.

**Tech Stack:** Flutter/Dart, Riverpod, go_router, Supabase Auth/Postgres/Storage/Edge Functions, Firebase Core/Messaging/Crashlytics/Analytics/Remote Config/Performance/App Check, Android Gradle, Firebase CLI, Supabase CLI or Supabase MCP, PowerShell, Android JDK 21.

---

## Current Context And Rules

- Current workspace: `C:\Users\Immabe\Vertiege`.
- Current branch should remain `main` unless the implementer creates a short-lived `codex/firebase-supabase-hybrid` branch for execution.
- Do not move app ownership to Firebase Auth, Firestore, or Realtime Database.
- Do not place Firebase service account JSON, Supabase service-role keys, or webhook secrets in the Flutter app.
- Do not enable App Check enforcement in Firebase Console until debug/release devices are verified.
- Do not deploy SQL blindly. Inspect remote schema, buckets, and migration history first.
- Build with JDK 21:

```powershell
$env:JAVA_HOME="C:\Users\Immabe\AppData\Local\jdk-21.0.9+10"
```

---

## File Structure

### Flutter Firebase Bootstrap

- Modify: `lib/main.dart`
  - Register the FCM background handler before `runApp`.
- Modify: `lib/services/firebase_bootstrap.dart`
  - Initialize Firebase, Crashlytics, Analytics, Performance, App Check, and Remote Config in a safe order.
- Modify: `lib/firebase_options.dart`
  - Keep generated by FlutterFire CLI only. Do not hand-edit except to verify it exists.
- Modify: `pubspec.yaml`
  - Ensure Firebase package set is complete and pinned through `pubspec.lock`.

### Notifications

- Modify: `lib/services/push_token_service.dart`
  - Request notification permission, register FCM tokens, listen to token refresh, handle foreground/opened/initial notifications, and store tokens in Supabase.
- Modify: `lib/services/firebase_messaging_handlers.dart`
  - Keep the top-level background handler and notification route parser.
- Modify: `lib/app.dart`
  - Listen for notification routes and navigate through `appRouterProvider`.
- Modify: `lib/repositories/notification_repository.dart`
  - Ensure notifications load from Supabase and mark-read mutations persist.
- Modify: `lib/state/notification_provider.dart`
  - Surface loading/error states rather than silently hiding failures.
- Modify: `lib/services/notification_service.dart`
  - Ensure app notification creation writes to Supabase `notifications`.

### Firebase Services

- Modify: `lib/services/crash_reporter.dart`
  - Use Firebase Crashlytics as the production reporter.
- Modify: `lib/services/analytics_service.dart`
  - Use Firebase Analytics and provide `NavigatorObserver`.
- Modify: `lib/services/remote_config_service.dart`
  - Define defaults for feature flags and runtime tuning.
- Create or modify: `lib/services/performance_service.dart`
  - Wrap Firebase Performance traces.
- Create or modify: `lib/services/app_check_service.dart`
  - Activate App Check with debug providers in debug and Play Integrity/App Attest in release.

### Google Login

- Modify: `lib/services/auth_service.dart`
  - Keep Supabase Auth as primary.
  - Either keep browser OAuth or add native Google ID token sign-in through Supabase.
- Modify: `lib/screens/auth/login_screen.dart`
  - Ensure Google login button reports real auth errors.
- Modify: `lib/screens/auth/auth_callback.dart`
  - Ensure Supabase deep-link callbacks resolve session and route correctly.
- Modify: `android/app/src/main/AndroidManifest.xml`
  - Keep `vertiege://auth/callback` intent filter.

### Android Firebase Config

- Modify: `android/settings.gradle.kts`
  - Keep Google Services, Crashlytics, and Firebase Performance Gradle plugins on current stable versions.
- Modify: `android/app/build.gradle.kts`
  - Apply Firebase plugins in app module.
- Modify: `android/app/src/main/AndroidManifest.xml`
  - Add notification permission and default FCM metadata if needed.
- Verify: `android/app/google-services.json`
  - Generated from Firebase Console. Do not commit if it contains wrong project/app.

### Supabase SQL And Storage

- Create: `supabase/migrations/YYYYMMDDHHMMSS_firebase_notification_infra.sql`
  - Create/repair `device_tokens`.
  - Add notification indexes.
  - Add optional notification trigger or webhook helper fields only if needed.
- Create: `supabase/migrations/YYYYMMDDHHMMSS_storage_bucket_completion.sql`
  - Create/repair storage buckets and policies.
- Modify: `supabase/storage_buckets.sql`
  - Keep as manual reference, but migrations are the source of truth.
- Modify: `supabase/functions/send-push/index.ts`
  - Send real FCM HTTP v1 messages from notification rows.

### CI And Release

- Modify: `.github/workflows/ci.yml`
  - Ensure analyze, tests, and APK release build run with JDK 21.
- Optional create: `.github/workflows/android-release.yml`
  - Upload release APK artifact after successful build.
- Modify: `firebase.json`
  - Ensure Firebase project config does not conflict with Supabase functions.

### Docs

- Create or modify: `docs/FIREBASE_SUPABASE_HYBRID_SETUP.md`
  - Document console setup, secrets, SQL, buckets, FCM, Google login, App Check, and verification.
- Modify: `README.md`
  - Add concise setup links and required secrets.
- Modify: `PLAN.md`
  - Reference this plan under infrastructure milestone if root plan is still used as current roadmap.

---

## Task 1: Baseline Audit And Branch Safety

**Files:**
- Inspect: `pubspec.yaml`
- Inspect: `pubspec.lock`
- Inspect: `lib/services/*.dart`
- Inspect: `android/settings.gradle.kts`
- Inspect: `android/app/build.gradle.kts`
- Inspect: `android/app/src/main/AndroidManifest.xml`
- Inspect: `supabase/functions/send-push/index.ts`
- Inspect: `supabase/migrations/*.sql`

- [ ] **Step 1: Capture git state**

Run:

```powershell
git status --short --branch
git log --oneline --decorate -8
```

Expected:
- Branch is clear enough to work from, or uncommitted Firebase changes are explicitly included in this plan's implementation.
- If creating a branch, use:

```powershell
git switch -c codex/firebase-supabase-hybrid
```

- [ ] **Step 2: Capture dependency state**

Run:

```powershell
flutter pub deps --style=compact | Select-String -Pattern "firebase_|supabase|google_sign_in"
```

Expected package families:
- `firebase_core`
- `firebase_messaging`
- `firebase_crashlytics`
- `firebase_analytics`
- `firebase_remote_config`
- `firebase_performance`
- `firebase_app_check`
- `supabase_flutter`
- `google_sign_in` only if native Google login is implemented.

- [ ] **Step 3: Capture current validation result**

Run:

```powershell
$env:JAVA_HOME="C:\Users\Immabe\AppData\Local\jdk-21.0.9+10"
flutter pub get
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test
```

Expected:
- Analyze exits `0`.
- Tests pass.
- Existing info-level suggestions may remain, but no compile errors.

- [ ] **Step 4: Commit only if starting from known-good partial work**

If the current changes compile and tests pass:

```powershell
git add pubspec.yaml pubspec.lock lib android firebase.json supabase .flutter-plugins-dependencies macos windows
git commit -m "chore: checkpoint firebase hybrid baseline"
```

If they do not compile, do not commit. Fix Task 2 and Task 3 first.

---

## Task 2: Stabilize Android Build With Firebase Plugins

**Files:**
- Modify: `android/gradle.properties`
- Modify: `android/settings.gradle.kts`
- Modify: `android/app/build.gradle.kts`
- Inspect: `android/hs_err_pid*.log`

- [ ] **Step 1: Inspect Gradle memory config**

Run:

```powershell
Get-Content android/gradle.properties
```

If Firebase Performance or Crashlytics causes Gradle daemon crashes on the local machine, change JVM args to this conservative JDK 21 config:

```properties
org.gradle.jvmargs=-Xmx3072m -XX:MaxMetaspaceSize=1024m -XX:+UseG1GC -Dfile.encoding=UTF-8
org.gradle.daemon=false
org.gradle.parallel=false
kotlin.compiler.execution.strategy=out-of-process
android.useAndroidX=true
android.enableJetifier=true
```

- [ ] **Step 2: Verify plugin versions**

`android/settings.gradle.kts` should include versions compatible with current Firebase Android tooling:

```kotlin
plugins {
    id("com.android.application") version "8.9.1" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
    id("com.google.gms.google-services") version "4.4.4" apply false
    id("com.google.firebase.crashlytics") version "3.0.6" apply false
    id("com.google.firebase.firebase-perf") version "2.0.2" apply false
}
```

If the app already uses newer compatible Android/Kotlin plugin versions, keep the repo's versions and only ensure Firebase plugins are present.

- [ ] **Step 3: Verify app module plugins**

`android/app/build.gradle.kts` should include:

```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    id("com.google.firebase.firebase-perf")
}
```

- [ ] **Step 4: Clean stale daemon state and build**

Run:

```powershell
cd android
.\gradlew --stop
cd ..
flutter clean
flutter pub get
flutter build apk --release
```

Expected:
- `build/app/outputs/flutter-apk/app-release.apk` exists.

- [ ] **Step 5: If the JVM crashes again, capture proof before changing strategy**

Run:

```powershell
Get-ChildItem android -Filter "hs_err_pid*.log" | Sort-Object LastWriteTime -Descending | Select-Object -First 1 | ForEach-Object { Get-Content $_.FullName -TotalCount 80 }
```

If the crash is inside the JVM and not a Dart/Gradle compile error, keep Firebase dependencies, temporarily remove only `id("com.google.firebase.firebase-perf")`, rebuild, and document that Performance auto-instrumentation is blocked by local Gradle/JDK stability. Keep manual `PerformanceService` in Flutter so instrumentation can be restored later.

- [ ] **Step 6: Commit build stabilization**

```powershell
git add android pubspec.yaml pubspec.lock .flutter-plugins-dependencies macos windows
git commit -m "chore: stabilize firebase android build"
```

---

## Task 3: Complete Firebase Bootstrap

**Files:**
- Modify: `lib/main.dart`
- Modify: `lib/services/firebase_bootstrap.dart`
- Modify: `lib/services/crash_reporter.dart`
- Modify: `lib/services/analytics_service.dart`
- Modify: `lib/services/remote_config_service.dart`
- Create or modify: `lib/services/performance_service.dart`
- Create or modify: `lib/services/app_check_service.dart`
- Test: `test/services/firebase_bootstrap_test.dart` if Firebase test mocking is already available; otherwise add focused tests for pure helpers only.

- [ ] **Step 1: Ensure FCM background handler is registered before app startup**

`lib/main.dart` must register the top-level handler after `WidgetsFlutterBinding.ensureInitialized()`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await FirebaseBootstrap.initialize();
  runApp(const ProviderScope(child: VertiegeApp()));
}
```

If the actual `main()` has additional setup, preserve it and only add the handler before `runApp`.

- [ ] **Step 2: Initialize Firebase services in safe order**

`FirebaseBootstrap.initialize()` should:
- Call `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` once.
- Install `FirebaseCrashReporter`.
- Initialize App Check.
- Initialize Analytics.
- Initialize Performance.
- Initialize Remote Config.
- Never crash the app if optional Firebase services fail.
- Report failures to `CrashReporter`.

Use this behavioral shape:

```dart
try {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  CrashReporter.install(await FirebaseCrashReporter.create());
  await AppCheckService.initialize();
  await AnalyticsService.initialize();
  await PerformanceService.initialize();
  await RemoteConfigService.initialize();
} catch (error, stackTrace) {
  await CrashReporter.instance.recordError(
    error,
    stackTrace,
    reason: 'Firebase bootstrap failed',
  );
}
```

- [ ] **Step 3: Ensure Crashlytics is production-ready**

`FirebaseCrashReporter.create()` should:
- Enable collection in release builds.
- Disable automatic collection in debug builds unless a debug flag says otherwise.
- Support breadcrumbs, custom keys, user id, and fatal/non-fatal errors.

- [ ] **Step 4: Ensure Analytics tracks navigation**

`AnalyticsService.navigatorObservers` should return:

```dart
[
  FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
]
```

only after Analytics is initialized. `lib/router/app_router.dart` should pass those observers to `GoRouter`.

- [ ] **Step 5: Ensure Remote Config has defaults**

`RemoteConfigService` should set defaults for:

```dart
const defaults = {
  'marketplace_enabled': false,
  'treasury_enabled': false,
  'quests_enabled': true,
  'events_enabled': true,
  'feed_page_size': 20,
  'channel_page_size': 30,
  'startup_feed_limit': 12,
  'verbose_errors_enabled': false,
  'maintenance_banner_enabled': false,
  'minimum_build_number': 1,
};
```

- [ ] **Step 6: Validate**

Run:

```powershell
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test
```

- [ ] **Step 7: Commit**

```powershell
git add lib test pubspec.yaml pubspec.lock
git commit -m "feat: complete firebase bootstrap services"
```

---

## Task 4: Complete Push Notifications In Flutter

**Files:**
- Modify: `lib/services/push_token_service.dart`
- Modify: `lib/services/firebase_messaging_handlers.dart`
- Modify: `lib/app.dart`
- Modify: `android/app/src/main/AndroidManifest.xml`
- Test: `test/services/firebase_messaging_handlers_test.dart`

- [ ] **Step 1: Add pure route parser tests**

Create `test/services/firebase_messaging_handlers_test.dart`:

```dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vertiege/services/firebase_messaging_handlers.dart';

RemoteMessage messageWith(Map<String, dynamic> data) => RemoteMessage(data: data);

void main() {
  test('uses explicit route when present', () {
    expect(routeFromRemoteMessage(messageWith({'route': '/chat/channel/abc'})), '/chat/channel/abc');
  });

  test('uses deeplink when route is absent', () {
    expect(routeFromRemoteMessage(messageWith({'deeplink': '/notifications/n1'})), '/notifications/n1');
  });

  test('maps post id to post route', () {
    expect(routeFromRemoteMessage(messageWith({'post_id': 'p1'})), '/post/p1');
  });

  test('maps channel id to channel route', () {
    expect(routeFromRemoteMessage(messageWith({'channel_id': 'c1'})), '/chat/channel/c1');
  });

  test('maps world id to world route', () {
    expect(routeFromRemoteMessage(messageWith({'world_id': 'w1'})), '/explore/w1');
  });

  test('returns null when data has no route target', () {
    expect(routeFromRemoteMessage(messageWith({'kind': 'unknown'})), isNull);
  });
}
```

- [ ] **Step 2: Run parser tests and fix compile issues**

Run:

```powershell
flutter test test/services/firebase_messaging_handlers_test.dart
```

Expected: tests pass.

- [ ] **Step 3: Implement resident-scoped FCM registration**

`PushTokenService.initializeForResident(String residentId)` must:
- Return `Future<String?>`, where the string is an initial notification route if the app was opened from a terminated state.
- No-op on web if not supported.
- No-op when Supabase is not configured, but record a breadcrumb explaining why.
- Request Android/iOS permission.
- Call `FirebaseMessaging.instance.getToken()`.
- Upsert token into Supabase `device_tokens`.
- Listen to `onTokenRefresh`.
- Register foreground and opened-app listeners only once.

Expected upsert payload:

```dart
{
  'resident_id': residentId,
  'token': token,
  'platform': defaultTargetPlatform.name,
  'app_version': packageInfo.version,
  'build_number': packageInfo.buildNumber,
  'last_seen_at': DateTime.now().toUtc().toIso8601String(),
}
```

- [ ] **Step 4: Handle foreground and opened notifications**

Foreground messages should:
- Log Analytics event `notification_foreground`.
- Record a CrashReporter breadcrumb.
- Update notification providers if the app has an existing refresh hook.

Opened messages should:
- Parse route through `routeFromRemoteMessage`.
- Emit the route through a broadcast stream.
- Log Analytics event `notification_opened`.

- [ ] **Step 5: Wire app navigation**

`lib/app.dart` should subscribe to notification route stream:

```dart
_notificationRouteSubscription = PushTokenService.notificationRoutes.listen((route) {
  if (!mounted || route.isEmpty) return;
  ref.read(appRouterProvider).go(route);
});
```

When resident bootstrap completes, call:

```dart
final initialRoute = await PushTokenService.initializeForResident(resident.id);
if (mounted && initialRoute != null) {
  ref.read(appRouterProvider).go(initialRoute);
}
```

- [ ] **Step 6: Add Android notification permission**

`android/app/src/main/AndroidManifest.xml` should include:

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

For Android 13+, the runtime permission request in Firebase Messaging is still required.

- [ ] **Step 7: Validate**

Run:

```powershell
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test
```

- [ ] **Step 8: Commit**

```powershell
git add lib android test
git commit -m "feat: wire firebase push notifications"
```

---

## Task 5: Complete Supabase Device Token SQL

**Files:**
- Create: `supabase/migrations/YYYYMMDDHHMMSS_firebase_notification_infra.sql`
- Inspect: `supabase/migrations/*.sql`
- Inspect remote: Supabase migration history and `device_tokens` table.

- [ ] **Step 1: Inspect remote before writing SQL**

Use Supabase MCP or CLI to run:

```sql
select table_name
from information_schema.tables
where table_schema = 'public'
  and table_name in ('device_tokens', 'notifications', 'residents', 'profiles');

select column_name, data_type
from information_schema.columns
where table_schema = 'public'
  and table_name in ('device_tokens', 'notifications')
order by table_name, ordinal_position;
```

Expected:
- Confirm whether `device_tokens` exists and whether user id columns are `text` or `uuid`.
- Confirm `notifications` recipient column is `recipient_id`, not `resident_id`.

- [ ] **Step 2: Create corrective migration**

Use a new sortable timestamp filename, for example:

```powershell
npx supabase migration new firebase_notification_infra
```

Migration content should be idempotent:

```sql
create table if not exists public.device_tokens (
  id uuid primary key default gen_random_uuid(),
  resident_id text not null references public.residents(id) on delete cascade,
  token text not null,
  platform text not null default 'unknown',
  app_version text,
  build_number text,
  last_seen_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists device_tokens_token_key
  on public.device_tokens (token);

create index if not exists device_tokens_resident_id_idx
  on public.device_tokens (resident_id);

create index if not exists notifications_recipient_created_idx
  on public.notifications (recipient_id, created_at desc);

alter table public.device_tokens enable row level security;

drop policy if exists "Device token owners can read their tokens" on public.device_tokens;
drop policy if exists "Device token owners can insert their tokens" on public.device_tokens;
drop policy if exists "Device token owners can update their tokens" on public.device_tokens;
drop policy if exists "Device token owners can delete their tokens" on public.device_tokens;
drop policy if exists "Superusers can manage device tokens" on public.device_tokens;

create policy "Device token owners can read their tokens"
  on public.device_tokens
  for select
  using (resident_id = auth.uid()::text);

create policy "Device token owners can insert their tokens"
  on public.device_tokens
  for insert
  with check (resident_id = auth.uid()::text);

create policy "Device token owners can update their tokens"
  on public.device_tokens
  for update
  using (resident_id = auth.uid()::text)
  with check (resident_id = auth.uid()::text);

create policy "Device token owners can delete their tokens"
  on public.device_tokens
  for delete
  using (resident_id = auth.uid()::text);

create policy "Superusers can manage device tokens"
  on public.device_tokens
  for all
  using (public.is_superuser())
  with check (public.is_superuser());
```

If `residents.id` is not the auth id, adjust only after verifying the resident/auth mapping in the existing schema.

- [ ] **Step 3: Apply safely to remote**

Preferred direct SQL execution:

```powershell
npx supabase db push --dry-run
```

If dry-run is not possible because the project is not linked, use Supabase MCP SQL execution with the migration content and record the result in `REPORT.md`.

- [ ] **Step 4: Smoke check**

Run:

```sql
select policyname, cmd
from pg_policies
where schemaname = 'public'
  and tablename = 'device_tokens'
order by policyname;

select indexname
from pg_indexes
where schemaname = 'public'
  and tablename in ('device_tokens', 'notifications')
order by tablename, indexname;
```

Expected:
- Owner policies exist.
- Superuser policy exists.
- Token uniqueness and recipient notification indexes exist.

- [ ] **Step 5: Commit**

```powershell
git add supabase/migrations REPORT.md
git commit -m "feat: add firebase notification token schema"
```

---

## Task 6: Complete Supabase Storage Buckets

**Files:**
- Create: `supabase/migrations/YYYYMMDDHHMMSS_storage_bucket_completion.sql`
- Modify: `supabase/storage_buckets.sql`
- Inspect remote: `storage.buckets`, `pg_policies`.

- [ ] **Step 1: Inspect existing buckets**

Run through Supabase MCP or SQL editor:

```sql
select id, name, public, file_size_limit, allowed_mime_types
from storage.buckets
where id in (
  'avatars',
  'post-media',
  'verification-proofs',
  'world-banners',
  'world-icons',
  'marketplace-media',
  'chat-attachments'
)
order by id;
```

- [ ] **Step 2: Create bucket migration**

Use a new sortable migration. The SQL should create or update buckets:

```sql
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('avatars', 'avatars', true, 5242880, array['image/jpeg', 'image/png', 'image/webp']),
  ('post-media', 'post-media', true, 26214400, array['image/jpeg', 'image/png', 'image/webp', 'video/mp4']),
  ('world-banners', 'world-banners', true, 10485760, array['image/jpeg', 'image/png', 'image/webp']),
  ('world-icons', 'world-icons', true, 5242880, array['image/jpeg', 'image/png', 'image/webp']),
  ('marketplace-media', 'marketplace-media', true, 26214400, array['image/jpeg', 'image/png', 'image/webp', 'video/mp4']),
  ('chat-attachments', 'chat-attachments', true, 26214400, array['image/jpeg', 'image/png', 'image/webp', 'video/mp4', 'application/pdf']),
  ('verification-proofs', 'verification-proofs', false, 10485760, array['image/jpeg', 'image/png', 'image/webp', 'application/pdf'])
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;
```

- [ ] **Step 3: Add storage policies**

Use policy names that will not collide with old manual SQL:

```sql
drop policy if exists "Authenticated users can upload app media" on storage.objects;
drop policy if exists "Owners can update app media" on storage.objects;
drop policy if exists "Owners can delete app media" on storage.objects;
drop policy if exists "Superusers can manage app media" on storage.objects;
drop policy if exists "Authenticated users can read verification proofs" on storage.objects;

create policy "Authenticated users can upload app media"
  on storage.objects
  for insert
  to authenticated
  with check (
    bucket_id in (
      'avatars',
      'post-media',
      'world-banners',
      'world-icons',
      'marketplace-media',
      'chat-attachments',
      'verification-proofs'
    )
  );

create policy "Owners can update app media"
  on storage.objects
  for update
  to authenticated
  using (
    owner = auth.uid()
    and bucket_id in (
      'avatars',
      'post-media',
      'world-banners',
      'world-icons',
      'marketplace-media',
      'chat-attachments',
      'verification-proofs'
    )
  )
  with check (
    owner = auth.uid()
    and bucket_id in (
      'avatars',
      'post-media',
      'world-banners',
      'world-icons',
      'marketplace-media',
      'chat-attachments',
      'verification-proofs'
    )
  );

create policy "Owners can delete app media"
  on storage.objects
  for delete
  to authenticated
  using (
    owner = auth.uid()
    and bucket_id in (
      'avatars',
      'post-media',
      'world-banners',
      'world-icons',
      'marketplace-media',
      'chat-attachments',
      'verification-proofs'
    )
  );

create policy "Superusers can manage app media"
  on storage.objects
  for all
  to authenticated
  using (public.is_superuser())
  with check (public.is_superuser());

create policy "Authenticated users can read verification proofs"
  on storage.objects
  for select
  to authenticated
  using (bucket_id = 'verification-proofs');
```

Public buckets are readable through public URLs. Do not add broad list policies unless the app explicitly needs bucket listing.

- [ ] **Step 4: Apply and smoke check**

Run:

```sql
select id, public
from storage.buckets
where id in (
  'avatars',
  'post-media',
  'verification-proofs',
  'world-banners',
  'world-icons',
  'marketplace-media',
  'chat-attachments'
)
order by id;

select policyname, cmd
from pg_policies
where schemaname = 'storage'
  and tablename = 'objects'
  and policyname ilike '%app media%'
order by policyname;
```

Expected:
- Seven app buckets exist.
- Verification proofs are private.
- Upload/update/delete policies exist.

- [ ] **Step 5: Commit**

```powershell
git add supabase/migrations supabase/storage_buckets.sql REPORT.md
git commit -m "feat: complete supabase media buckets"
```

---

## Task 7: Complete Supabase Edge Function Push Fanout

**Files:**
- Modify: `supabase/functions/send-push/index.ts`
- Optional create: `supabase/functions/send-push/README.md`
- Modify: `docs/FIREBASE_SUPABASE_HYBRID_SETUP.md`

- [ ] **Step 1: Verify function contract**

`send-push` should accept a Supabase DB webhook body containing a new `notifications` row:

```json
{
  "type": "INSERT",
  "table": "notifications",
  "record": {
    "id": "notification-id",
    "recipient_id": "resident-id",
    "title": "Title",
    "body": "Body",
    "route": "/notifications/notification-id",
    "post_id": null,
    "channel_id": null,
    "world_id": null
  }
}
```

- [ ] **Step 2: Enforce webhook auth**

The function must require:

```text
Authorization: Bearer ${WEBHOOK_SECRET}
```

If missing or wrong, return `401`.

- [ ] **Step 3: Query device tokens with service role only**

Use environment variables:

```text
SUPABASE_URL
SUPABASE_SERVICE_ROLE_KEY
FIREBASE_SERVICE_ACCOUNT_JSON
WEBHOOK_SECRET
```

Never expose these values to Flutter.

- [ ] **Step 4: Send FCM HTTP v1 messages**

Function should:
- Build OAuth access token from `FIREBASE_SERVICE_ACCOUNT_JSON`.
- Send to `https://fcm.googleapis.com/v1/projects/{project_id}/messages:send`.
- Include both notification and data payload.
- Include Android channel id `vertiege_notifications`.
- Remove invalid tokens when FCM returns `UNREGISTERED` or token-specific `INVALID_ARGUMENT`.
- Return a JSON summary:

```json
{
  "sent": 3,
  "failed": 1,
  "deletedInvalidTokens": 1
}
```

- [ ] **Step 5: Deploy secrets**

Run:

```powershell
npx supabase secrets set WEBHOOK_SECRET="<generate-strong-secret>"
npx supabase secrets set FIREBASE_SERVICE_ACCOUNT_JSON="<single-line-service-account-json>"
npx supabase secrets set SUPABASE_SERVICE_ROLE_KEY="<remote-service-role-key>"
```

If using Supabase MCP instead of CLI, set the same secrets through the project function secrets UI/tool.

- [ ] **Step 6: Deploy function**

Run:

```powershell
npx supabase functions deploy send-push
```

- [ ] **Step 7: Configure notification webhook**

In Supabase Dashboard:
- Database Webhooks.
- Table: `public.notifications`.
- Event: `INSERT`.
- Method: `POST`.
- URL: `https://wjaphoaxalvgjnrwqjwe.supabase.co/functions/v1/send-push`.
- Headers:

```text
Authorization: Bearer <WEBHOOK_SECRET>
Content-Type: application/json
```

If webhook SQL is preferred and `pg_net` is enabled, add a migration only after verifying extension availability.

- [ ] **Step 8: Smoke test with a real resident**

Insert a notification for a resident with a registered device token:

```sql
insert into public.notifications (
  recipient_id,
  title,
  body,
  route,
  created_at
) values (
  '<resident-id>',
  'Vertiege test',
  'Push fanout is live',
  '/notifications',
  now()
);
```

Expected:
- Function logs show successful FCM send.
- Device receives notification when app is backgrounded.
- Tapping the notification opens the app route.

- [ ] **Step 9: Commit**

```powershell
git add supabase/functions/send-push docs
git commit -m "feat: send supabase notifications through fcm"
```

---

## Task 8: Complete Google Login Through Supabase

**Files:**
- Modify: `lib/services/auth_service.dart`
- Modify: `lib/screens/auth/login_screen.dart`
- Modify: `lib/screens/auth/auth_callback.dart`
- Modify: `android/app/src/main/AndroidManifest.xml`
- Modify: `docs/FIREBASE_SUPABASE_HYBRID_SETUP.md`

**Decision:** Use Supabase Auth as the owner of login. Firebase Auth should not be introduced because it creates two auth authorities. Firebase can provide Google project infrastructure, OAuth client IDs, Analytics, and Crashlytics, but Supabase should issue the app session.

- [ ] **Step 1: Keep browser OAuth as the default simplest path**

`AuthService.signInWithGoogle()` should use:

```dart
await Supabase.instance.client.auth.signInWithOAuth(
  OAuthProvider.google,
  redirectTo: 'vertiege://auth/callback',
);
```

The callback screen should then read:

```dart
final session = Supabase.instance.client.auth.currentSession;
```

or listen to `onAuthStateChange` if the session is not immediately available.

- [ ] **Step 2: Configure Google OAuth in dashboards**

In Google Cloud Console:
- Create or reuse OAuth client.
- Add Supabase redirect URI:

```text
https://wjaphoaxalvgjnrwqjwe.supabase.co/auth/v1/callback
```

In Supabase Dashboard:
- Authentication > Providers > Google.
- Enable Google.
- Paste Google OAuth client ID and secret.
- Authentication > URL Configuration.
- Add allowed redirect URL:

```text
vertiege://auth/callback
```

- [ ] **Step 3: Verify Android callback intent**

`android/app/src/main/AndroidManifest.xml` should contain an intent filter for the callback activity:

```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="vertiege" android:host="auth" android:path="/callback" />
</intent-filter>
```

- [ ] **Step 4: Optional native Google Sign-In path**

Use this only if browser OAuth UX is not acceptable. Add native sign-in through `google_sign_in` and exchange the Google ID token with Supabase:

```dart
final googleSignIn = GoogleSignIn.instance;
await googleSignIn.initialize(serverClientId: '<web-client-id>');
final account = await googleSignIn.authenticate();
final authentication = account.authentication;
final idToken = authentication.idToken;
if (idToken == null) {
  throw const AuthException('Google did not return an ID token.');
}

await Supabase.instance.client.auth.signInWithIdToken(
  provider: OAuthProvider.google,
  idToken: idToken,
);
```

This requires Android OAuth SHA-1/SHA-256 fingerprints in Google Cloud/Firebase and a web client id for server auth.

- [ ] **Step 5: Manual acceptance**

On installed APK:
- Tap Google login.
- Complete Google account selection.
- Return to app through `vertiege://auth/callback`.
- Confirm resident/profile bootstrap completes.
- Confirm push token registration runs after resident is available.

- [ ] **Step 6: Commit**

```powershell
git add lib android docs
git commit -m "feat: document and verify supabase google login"
```

---

## Task 9: Complete Firebase Console Setup Checklist

**Files:**
- Modify: `docs/FIREBASE_SUPABASE_HYBRID_SETUP.md`
- Inspect: Firebase Console.

- [ ] **Step 1: Verify Firebase Android app**

In Firebase Console:
- Project is correct for Vertiege.
- Android app package matches `android.defaultConfig.applicationId`.
- `google-services.json` in `android/app/google-services.json` is from that app.

- [ ] **Step 2: Enable Cloud Messaging**

Verify:
- FCM API enabled.
- Sender ID exists.
- Device token is generated on real device.
- Test notification from Firebase Console reaches the app.

- [ ] **Step 3: Enable Crashlytics**

Verify:
- Crashlytics SDK receives builds.
- Add a debug-only crash test button or temporary code path only if necessary.
- Remove crash test before release.

- [ ] **Step 4: Enable Analytics**

Verify:
- DebugView receives events from installed APK.
- Navigation events are visible.
- Events do not contain message text, post text, email, or other PII.

- [ ] **Step 5: Enable Remote Config**

Create keys matching `RemoteConfigService` defaults:

```text
marketplace_enabled
treasury_enabled
quests_enabled
events_enabled
feed_page_size
channel_page_size
startup_feed_limit
verbose_errors_enabled
maintenance_banner_enabled
minimum_build_number
```

- [ ] **Step 6: Enable Performance Monitoring**

Verify:
- App startup and custom traces appear.
- If Gradle auto-instrumentation was disabled due build crashes, document that custom Flutter traces are active and Android auto-instrumentation is deferred.

- [ ] **Step 7: Configure App Check**

For Android:
- Register Play Integrity provider for release package.
- Add debug token for development device.
- Do not enforce until debug and release APK both pass login, Supabase calls, FCM, Remote Config, and Crashlytics.

- [ ] **Step 8: Commit docs**

```powershell
git add docs/FIREBASE_SUPABASE_HYBRID_SETUP.md README.md
git commit -m "docs: add firebase console setup checklist"
```

---

## Task 10: End-To-End Notification Verification

**Files:**
- Modify only if issues are found:
  - `lib/services/push_token_service.dart`
  - `lib/services/firebase_messaging_handlers.dart`
  - `supabase/functions/send-push/index.ts`
  - `supabase/migrations/*.sql`

- [ ] **Step 1: Install fresh release APK**

Run:

```powershell
$env:JAVA_HOME="C:\Users\Immabe\AppData\Local\jdk-21.0.9+10"
flutter build apk --release
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

- [ ] **Step 2: Login and verify token registration**

After logging in:

```sql
select resident_id, platform, app_version, build_number, last_seen_at
from public.device_tokens
where resident_id = '<current-resident-id>'
order by last_seen_at desc
limit 5;
```

Expected:
- At least one current token row.

- [ ] **Step 3: Foreground notification test**

With app open, insert:

```sql
insert into public.notifications (recipient_id, title, body, route, created_at)
values ('<current-resident-id>', 'Foreground test', 'App is open', '/notifications', now());
```

Expected:
- Supabase notification row appears in app notification UI.
- FCM foreground handler logs breadcrumb/event.

- [ ] **Step 4: Background notification test**

Put app in background and insert:

```sql
insert into public.notifications (recipient_id, title, body, route, created_at)
values ('<current-resident-id>', 'Background test', 'Tap to open notifications', '/notifications', now());
```

Expected:
- Device receives push.
- Tapping push opens `/notifications` or equivalent notifications UI.

- [ ] **Step 5: Terminated notification test**

Force-close app, insert:

```sql
insert into public.notifications (recipient_id, title, body, route, created_at)
values ('<current-resident-id>', 'Cold start test', 'Tap from terminated state', '/notifications', now());
```

Expected:
- Tapping push opens app and navigates to notification route after bootstrap.

- [ ] **Step 6: Token refresh test**

On device:

```powershell
adb shell pm clear <application-id>
```

Re-login, then verify old invalid tokens are not used forever and new token is upserted.

- [ ] **Step 7: Commit fixes**

If changes were needed:

```powershell
git add lib supabase docs
git commit -m "fix: harden notification end-to-end routing"
```

---

## Task 11: Add CI Release APK Artifact

**Files:**
- Modify: `.github/workflows/ci.yml`
- Optional create: `.github/workflows/android-release.yml`

- [ ] **Step 1: Ensure CI uses JDK 21**

Workflow should include:

```yaml
- uses: actions/setup-java@v4
  with:
    distribution: temurin
    java-version: '21'
```

- [ ] **Step 2: Ensure Flutter setup and dependency install**

```yaml
- uses: subosito/flutter-action@v2
  with:
    channel: stable

- run: flutter pub get
```

- [ ] **Step 3: Ensure validation commands**

```yaml
- run: flutter analyze --no-fatal-infos --no-fatal-warnings
- run: flutter test
- run: flutter build apk --release
```

- [ ] **Step 4: Upload APK artifact**

```yaml
- uses: actions/upload-artifact@v4
  with:
    name: vertiege-release-apk
    path: build/app/outputs/flutter-apk/app-release.apk
```

- [ ] **Step 5: Commit**

```powershell
git add .github/workflows
git commit -m "ci: build and upload release apk"
```

---

## Task 12: Final Verification And Handoff

**Files:**
- Modify: `REPORT.md`
- Modify: `docs/FIREBASE_SUPABASE_HYBRID_SETUP.md`

- [ ] **Step 1: Run final local checks**

```powershell
$env:JAVA_HOME="C:\Users\Immabe\AppData\Local\jdk-21.0.9+10"
flutter pub get
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test
flutter build apk --release
```

- [ ] **Step 2: Run Supabase smoke checks**

```sql
select count(*) as device_token_count from public.device_tokens;

select id, public
from storage.buckets
where id in (
  'avatars',
  'post-media',
  'verification-proofs',
  'world-banners',
  'world-icons',
  'marketplace-media',
  'chat-attachments'
)
order by id;

select policyname, tablename
from pg_policies
where (schemaname = 'public' and tablename = 'device_tokens')
   or (schemaname = 'storage' and tablename = 'objects')
order by schemaname, tablename, policyname;
```

- [ ] **Step 3: Run manual acceptance**

Use installed APK:
- Google login returns to app and creates/loads resident.
- Push permission prompt appears on Android 13+.
- Device token is inserted into Supabase.
- Foreground notification updates app state.
- Background notification appears in notification shade.
- Tapping notification opens the correct route.
- Crashlytics receives a non-fatal test error.
- Analytics DebugView receives navigation and notification events.
- Remote Config fetch uses defaults if network/config is unavailable.
- App Check debug token is registered before enforcement.

- [ ] **Step 4: Document what still requires dashboard/manual setup**

In `REPORT.md`, include:

```markdown
## Firebase/Supabase Hybrid Completion
- Firebase services completed:
- Supabase SQL applied:
- Storage buckets verified:
- Edge Function deployed:
- Google login configuration:
- APK path:
- Manual checks passed:
- Manual console steps still required:
```

- [ ] **Step 5: Commit and push**

```powershell
git add REPORT.md docs README.md
git commit -m "docs: record firebase supabase hybrid verification"
git status --short --branch
git push origin main
```

---

## Best Approach For Google Login

Use **Supabase Auth with Google provider** as the default approach.

Why:
- Supabase already owns app auth, profiles, RLS, residents, superuser access, and data permissions.
- Supabase sessions map directly to Postgres `auth.uid()` and RLS policies.
- Firebase Auth would create a second identity source and require custom token bridging or duplicated profile linking.
- Firebase is still useful for the Google Cloud project, OAuth client configuration, Analytics, Crashlytics, FCM, App Check, and Remote Config.

Recommended first implementation:
- Keep `signInWithOAuth(OAuthProvider.google, redirectTo: 'vertiege://auth/callback')`.
- Configure Google provider in Supabase.
- Configure Supabase callback URL in Google Cloud.
- Configure app deep link in Android manifest.

Recommended later improvement:
- Add native Google Sign-In with `google_sign_in` and `supabase.auth.signInWithIdToken` only if browser OAuth feels too clunky.

---

## SQL And Bucket Decision Checklist

Before applying anything:

- [ ] Check remote migration history.
- [ ] Check whether `device_tokens` exists.
- [ ] Check whether `notifications.recipient_id` exists and is indexed.
- [ ] Check whether the seven media buckets exist.
- [ ] Check whether storage policies already exist with conflicting names.
- [ ] Check whether `public.is_superuser()` exists.
- [ ] Check whether `residents.id` equals `auth.uid()::text` or uses another mapping.

Apply SQL only when:

- [ ] It is idempotent.
- [ ] It does not rewrite applied migrations.
- [ ] It can run on a fresh project.
- [ ] It can run on the existing remote project.
- [ ] It has smoke-check SQL after execution.

---

## External Setup Required

### Firebase Console

- Enable Android app and download `google-services.json`.
- Enable FCM.
- Enable Crashlytics.
- Enable Analytics.
- Enable Remote Config.
- Enable Performance Monitoring.
- Configure App Check providers but do not enforce until tested.
- Create service account JSON for FCM HTTP v1 and store only in Supabase Edge Function secrets.

### Supabase Dashboard

- Enable Google provider.
- Add `vertiege://auth/callback` to allowed redirect URLs.
- Deploy `send-push`.
- Set Edge Function secrets.
- Configure notification INSERT webhook to call `send-push`.
- Confirm storage buckets and policies.

### Google Cloud Console

- Add Supabase OAuth redirect URI:

```text
https://wjaphoaxalvgjnrwqjwe.supabase.co/auth/v1/callback
```

- If native Google Sign-In is added later, configure Android OAuth client SHA-1/SHA-256 fingerprints.

---

## References

- Firebase Flutter setup: https://firebase.google.com/docs/flutter/setup
- Firebase Cloud Messaging Flutter: https://firebase.google.com/docs/cloud-messaging/flutter/client
- Firebase Crashlytics Flutter: https://firebase.google.com/docs/crashlytics/get-started?platform=flutter
- Firebase Analytics Flutter: https://firebase.google.com/docs/analytics/get-started?platform=flutter
- Firebase Remote Config Flutter: https://firebase.google.com/docs/remote-config/get-started?platform=flutter
- Firebase Performance Flutter: https://firebase.google.com/docs/perf-mon/get-started-flutter
- Firebase App Check Flutter: https://firebase.google.com/docs/app-check/flutter/default-providers
- Supabase Google Auth: https://supabase.com/docs/guides/auth/social-login/auth-google
- Supabase Dart `signInWithIdToken`: https://supabase.com/docs/reference/dart/auth-signinwithidtoken

---

## Self-Review

- Spec coverage: This plan covers push notifications, background notification routing, Google login, Firebase infrastructure, Supabase SQL, storage buckets, Edge Function fanout, CI APK build, and final verification.
- Placeholder scan: No task uses `TBD`, `TODO`, or vague "handle edge cases" wording without concrete commands or acceptance.
- Type consistency: Route parser, device token fields, storage bucket names, and Supabase notification column names are consistent across tasks.

---

## Source: `docs/archive/plans/2026-05-22-image-asset-refresh.md`

# Image asset refresh — Vertiege

**Goal:** Replace outdated `assets/generated/` art with a coherent, on-brand set that matches each world name, profession, and achievement category.

**Inventory:** 64 files (see manifest below). Code reads paths from `lib/utils/world_assets.dart` and `lib/config/cosmetics.dart` — **filenames must stay the same** unless you update those maps in the same PR.

---

## Can your $20 Codex plan do this?

| Tool | Best for |
|------|----------|
| **Codex / ChatGPT (coding)** | Writing prompts, batch scripts, resizing, renaming, PR checklist — not always image output |
| **ChatGPT image generation** (if included in your subscription) | One-off or small batches from the prompt table below |
| **OpenAI Images API** (DALL·E / gpt-image) | Scripted batch generation; billed per image, separate from Codex tokens |
| **Cursor GenerateImage** | Spot-check style references (1–3 hero images) before a full batch |

**Practical approach:** Use Codex to run the **pipeline** (manifest + prompts + `scripts/validate_assets.ps1`), and use **ChatGPT Images or the Images API** for actual pixels. Do not rename files without updating Dart maps.

---

## Art direction (lock this first)

**Brand:** “Tier-gated social worlds” — premium, slightly futuristic, not cartoonish.

### Hard rules (non‑negotiable)

| Rule | Applies to |
|------|------------|
| **No text anywhere in the image** | **All `world-*.jpg` banners** and **all `badge-*.png` / `prof-*.png`** |
| No letters, numbers, words, logos, street signs, neon signage, UI labels, watermarks | Banners + badges (and still avoid on everything else) |
| **Transparent background** | `badge-*.png`, `prof-*.png`, `ach-*.png`, `tier-*.png` |
| Full-bleed background OK (opaque) | `world-*.jpg`, `bg-*.jpg`, `empty-*.jpg` |
| Avatars | PNG; **prefer transparent** around the bust so `CircleAvatar` clips cleanly (soft vignette OK, no rectangular frame) |

**Why:** Banners sit under gradients and UI copy in-app — any baked-in text clashes with world names. Badges render on coloured tiles; they must be **icon-only emblems** on **alpha**, not stickers on white squares.

| Rule | Value |
|------|--------|
| Mood | Cinematic, high contrast, subtle neon accents |
| Palette | Black / white base, violet `#7C3AED`, blue `#007AFF`, gold highlights |
| Worlds | Wide **16:9** environment art only — **zero typography** in pixels |
| Badges / prof | **1:1** emblem, metallic rim, **alpha PNG**, readable at 48dp |
| Achievements | **1:1** category metaphor, same emblem style, **alpha PNG** |
| Tiers | **1:1** medal crest (bronze → diamond), **alpha PNG** |
| Empty states | Soft illustration, AMOLED-friendly **opaque** JPG |

### Negative prompts

**Banners (`world-*.jpg`) — append every time:**
```
no text, no letters, no numbers, no words, no logos, no signage, no neon signs with writing,
no watermarks, no UI, no captions, no banners with typography, no storefront names
```

**Badges & professions (`badge-*.png`, `prof-*.png`) — append every time:**
```
no text, no letters, no numbers, no words, no labels, no initials, no monograms,
transparent background, isolated emblem only, no white square backdrop, no drop shadow card
```

**All other PNGs (ach, tier, avatar):**
```
no text, no watermark, transparent background (avatars: transparent or soft vignette only),
no UI mockup, not clipart, not anime
```

**General (everything):** blurry, low contrast, oversaturated, crowded composition.

---

## Output specs (Flutter)

| Asset | File pattern | Size (px) | Format | Background |
|-------|----------------|------------|--------|------------|
| World banner | `world-{slug}.jpg` | **1200×675** (16:9) | JPG q85 | **Opaque** full scene |
| Avatar | `avatar-*.png` | **512×512** | PNG | **Transparent** preferred |
| Badge / profession | `badge-*.png`, `prof-*.png` | **512×512** | PNG | **Transparent (required)** |
| Achievement category | `ach-*.png` | **512×512** | PNG | **Transparent (required)** |
| Tier | `tier-*.png` | **512×512** | PNG | **Transparent (required)** |
| Empty / BG | `empty-*.jpg`, `bg-*.jpg` | **1080×1920** or **1200×800** | JPG | Opaque |

**Post-processing (if the model returns a white/coloured plate behind badges):**
- Remove background → true alpha (e.g. rembg, Photoshop, Photoroom).
- Reject any output that has readable characters — regen rather than ship.

After generation: resize with ImageMagick/ffmpeg; **verify alpha** on PNGs before commit.

```powershell
# Quick check: PNG has transparency (ImageMagick)
magick identify -format "%[opaque]" assets/generated/badge-doctor.png
# "false" = has transparency (good for emblems)
```

---

## World banners — prompt template

Use **one prompt per slug**; keep filename unchanged.

```
Cinematic wide establishing shot for a digital community themed as {THEME_ONE_LINE}.
Visual only: {MOTIF}. Environment and atmosphere only — do not depict the name "{DISPLAY_NAME}" as text.
Lighting: dramatic rim light, deep shadows, subtle violet and gold accents.
Style: premium mobile game key art, photorealistic environment, no people.
CRITICAL: absolutely no text, letters, signs, logos, or readable writing anywhere in the image.
Aspect ratio 16:9, full-bleed opaque photograph.
```

| Slug | DISPLAY_NAME | THEME | MOTIF |
|------|--------------|-------|-------|
| aetheria | Aetheria | ethereal high society | floating terraces in mist, soft aurora |
| arts-pavilion | Arts Pavilion | creative elite | modern gallery at dusk, sculpture garden |
| aviation-heights | Aviation Heights | aviation prestige | airport skyline, runway lights, dawn |
| azure-coast | Azure Coast | coastal luxury | cliff villas, turquoise water, golden hour |
| crimson-court | Crimson Court | power & ceremony | crimson-lit grand hall, velvet, chandeliers |
| crystal-shore | Crystal Shore | serene wealth | crystal-clear bay, minimalist piers |
| financial-district | Financial District | finance capital | glass towers, trading floor glow at night |
| golden-estate | Golden Estate | old money estate | manor drive, hedges, warm sunset |
| legal-plaza | Legal Plaza | law & order | courthouse columns, marble, blue hour |
| medical-nexus | Medical Nexus | medical excellence | futuristic hospital campus, clean white+violet |
| neon-district | Neon District | cyber nightlife | neon alley, rain reflections, purple+pink — **glowing shapes only, no readable signs** |
| nova-station | Nova Station | space / research | orbital station window, nebula view |
| quantum-core | Quantum Core | tech / science | particle accelerator aesthetic, blue energy |
| silver-page | Silver Page | media & publishing | abstract press room, paper stacks — **no headlines or pages with writing** |
| sovereign-city | Sovereign City | capital metropolis | panoramic city crown, citadel center — **no skyline text** |
| tech-sprawl | Tech Sprawl | startup megacity | dense tech campus, holographic light shapes — **no billboards with words** |

---

## Other asset prompts (short)

**Avatars (`avatar-1` … `avatar-6`):** “Studio portrait bust, diverse {gender/ethnicity}, violet rim light, **transparent background**, no text, no name tag, 1:1 PNG.”

**Named avatars:** Distinct faces only — **do not render the name as text** on the image.

**Professions (`prof-*.png`):** Single iconic object (stethoscope, blueprints, gavel, chart, palette, wings) as **3D metallic emblem, centered, transparent PNG, no text, no circular plaque with letters**.

**Badges (`badge-*.png`):** Same as professions — **symbol only** (marathon shoe, quill, laurel, compass…). **No badge captions, no “MD”, no rank numbers.**

**Achievement categories (`ach-*.png`):** Metaphor icons (books, briefcase, hearts, dumbbell, wrench, plane, coins, handshake, mask, palette) — **transparent PNG, no labels**.

**Tiers:** Bronze / silver / gold / diamond **medallions** — ornate metal only, **no tier name engraved**.

**Empty states:** `empty-feed` (quiet timeline), `empty-chat` (speech bubbles), `empty-worlds` (portal), `empty-notifications` (bell) — minimal, dark background.

**Backgrounds:** `bg-splash`, `bg-onboarding` — abstract violet/black gradients, no characters.

---

## Codex workflow (resumable — use this)

**Start:** [docs/assets/CODEX_START_HERE.md](../assets/CODEX_START_HERE.md)

```powershell
.\scripts\image_gen.ps1 next      # one job + prompts (JSON)
.\scripts\image_gen.ps1 mark -Id <id> -Status generated
.\scripts\image_gen.ps1 status    # progress
.\scripts\image_gen.ps1 promote -All   # when ready: staging → assets/generated
```

Files save to **`assets/staging/generated/`** (in repo — Cursor/Codex can read them). State tracked in **`docs/assets/image-manifest.json`**.

4. Run validation:
   ```powershell
   ./scripts/validate_assets.ps1
   flutter test
   ```
5. **One PR** `assets: refresh generated art` — no Dart changes if names unchanged.
6. **Manual check** on device: world detail hero, explore cards, achievement grid, default avatars.

---

## Accuracy checklist (fix “inaccurate” assets)

| Problem | Fix |
|---------|-----|
| World image doesn’t match name | Regenerate using table above; verify slug ↔ file |
| Medical world looks generic | Emphasize clinical / campus motif in prompt |
| Neon-district not neon | Force “neon alley, rain, night” in every regen |
| Badge doesn’t match profession | Align `badge-*` with `prof-*` visual language |
| Text baked into banner/badge | Reject file; regen with CRITICAL no-text block; check neon/city slugs especially |
| White square behind badge | Run background removal; require alpha PNG |
| Tier 4 and 5 share diamond art | Add `tier-platinum.png` in a follow-up if product wants 5 distinct tiers |

---

## Optional phase 2 (Supabase)

User-uploaded world banners already support `world-banners` bucket. Generated assets are **fallbacks** for seed worlds. Custom worlds can use uploaded banners later; local assets remain defaults for offline/demo.

---

## File manifest (64)

```
ach-career.png ach-community.png ach-creative.png ach-education.png ach-finance.png
ach-funny.png ach-health.png ach-relationships.png ach-skills.png ach-travel.png
avatar-1.png … avatar-6.png avatar-alistair.png avatar-elena.png avatar-marcus.png
badge-*.png (14) prof-*.png (6) tier-bronze.png tier-silver.png tier-gold.png tier-diamond.png
bg-onboarding.jpg bg-splash.jpg empty-chat.jpg empty-feed.jpg empty-notifications.jpg empty-worlds.jpg
world-aetheria.jpg … world-tech-sprawl.jpg (16)
```

Full path map: `lib/utils/world_assets.dart`.

---

## Source: `docs/archive/plans/2026-05-22-screen-rebuild-plan.md`

# Screen rebuild plan — World, Identity, Achievements

**Date:** 2026-05-22  
**Status:** Phases A–D implemented on `develop` (Waves 1–4 + screen depth pass; device UAT in `docs/uat/WAVE-4-DEVICE-CHECKLIST.md`)  
**Reference UI:** `VHubPage` + `VSectionList` (More, Settings, Discover)

---

## What we fixed in this batch (install & verify first)

| Area | Change |
|------|--------|
| **Navigation** | `GoRouter` no longer rebuilds on every XP/profile update |
| **DM from profile** | `/dm/:roomId` top-level route (no white screen) |
| **League XP** | Standings scoped to **active season**; league loads on app start |
| **World detail scroll** | `NestedScrollView` — hero + stats + tabs scroll together |
| **Channel unread** | Own messages excluded; mark read after send |
| **DM realtime** | Subscribe all rooms when DM list loads |
| **DM alerts** | In-app notification row for recipient (DB `notifications`) |
| **Daily quests** | `/daily-quests` (not `/challenges`) |

---

## Problem summary (from UAT)

### World info (`WorldDetailScreen`)

- Banner + 4 stat cards felt **pinned** while only tab body scrolled.
- Visual language mixed **legacy glass** + new tokens; “readable but ugly.”
- **More** tab cluttered; chat preview duplicated channel entry.

### Identity tab

- Layout unlike **More / Settings** hub pattern.
- Refresh was confusing (fixed: stays on Identity).
- Many actions buried in long scroll; tier/XP/subscription not scannable.

### Achievements

- Index uses **legacy Scaffold + AppBar**, not Forui hub.
- Categories feel disconnected from **verifier proof** flow.
- User expectation: “major UX overhaul,” not small patches.

---

## Proposed phases

### Phase A — Shell parity (1–2 days)

**Goal:** All three screens use the same hub chrome as More/Settings.

| Screen | Deliverable |
|--------|-------------|
| Identity | `VHubPage` + sections: Profile, Progress, Worlds, Social, Account |
| Achievements | `VHubPage` + hero stats + category `FTile` grid |
| World detail | Keep immersive hero; stats as `FCard` row; tabs as `FHeader` segments |

**Exit criteria:** No raw `AppBar` on these flows; back navigation consistent.

### Phase B — World info UX (2–3 days)

**Goal:** One coherent “world home” that sells the world and routes to actions.

**Information architecture:**

```
[Hero: banner, name, tier, join/leave]
[Stats: members · posts · events · prestige]
[Primary actions: Feed | Channels | People | Manage]
[Optional: General chat preview — single CTA, not full composer]
[Tab content]
```

**Ideas:**

- **Sticky mini-header** after scroll (world name + join state only).
- **Sovereign row** under title (avatar + “Founded by …”).
- **Channel shortcuts** on Feed tab (General, Announcements) before posts.
- **Empty states** per tab with one clear CTA (join, post, invite).
- Move treasury/marketplace/polls behind **Manage** sub-sheet for members+.

### Phase C — Identity hub (2 days)

**Goal:** “My resident card” — status, progress, shortcuts.

**Sections (top → bottom):**

1. **Profile card** — avatar, nameplate, tier, edit, share profile  
2. **Today** — streak, daily quests link, league snippet  
3. **Progress** — XP bar, next tier, subscription badge  
4. **My worlds** — joined worlds (chips → world detail)  
5. **Social** — allies, following count → search  
6. **Vault** — trophies, cosmetics preview  
7. **Account** — settings, notifications, sign out  

**Ideas:**

- Pull-to-refresh reloads resident + posts + quests (no navigation).
- **Completion meter** (profile fields) like LinkedIn strength.
- Tap tier opens Ascension Path, not buried in More.

### Phase D — Achievements overhaul (3–4 days)

**Goal:** Browse → understand → submit proof → track verification.

**Flows:**

```
Index (categories + tier progress)
  → Category grid (locked / in-progress / verified)
    → Achievement detail (criteria, proof, status)
      → Submit (camera / gallery / manual)
```

**Ideas:**

- **Proof-first cards** — thumbnail or “manual review” badge on tile.
- **Verifier status chip** — pending / verified / rejected with reason.
- **Category progress** — “12/40 verified” per category.
- **Funny / Creative** categories visually distinct (tertiary accent).
- Profession achievements link to **verification portal** copy for staff.
- Share verified achievement as image card (existing share infra).

### Phase E — Push & polish (1 day, backend-dependent)

- FCM payload: `room_id`, `route: /dm/{id}` for DM opens.
- World channel mention notifications.
- League weekly reset banner on Monday.

---

## Design ideas (cross-cutting)

| Idea | Where | Why |
|------|--------|-----|
| **Hub sections** | Identity, Achievements index | Matches More tab mental model |
| **Immersive + hub hybrid** | World detail | Hero stays cinematic; controls feel modern |
| **Bento on Nexus only** | Not on world page | Reduces visual noise in world context |
| **Skeleton loaders** | All three | UAT called out “empty” vs “loading” confusion |
| **Error banners** | World join, achievement submit | Retry without kicking to Nexus |
| **Deep links** | `/dm/`, `/explore/:id`, `/achievements/:cat` | Notifications and share |

---

## Decisions (2026-05-22) — complete

| Topic | Choice |
|-------|--------|
| World hero | **Collapsible** — expand on pull-down |
| Rebuild order | **Parallel** — shell parity on all three, then depth per screen |
| Identity focus | **Wall of Honour** — rank, tiers, badges, worlds, achievements, perks |
| World Manage tab | **Split** — economy (treasury, marketplace, polls) in **Manage**; social extras on world **More** tab |
| Achievement proof | **In-app photo / gallery upload** |
| Visual reference | **Reddit** — community header + tabs |

---

## Questions (answered — archive)

---

## Out of scope (unless you say otherwise)

- Full verifier portal redesign (separate staff app surface).
- Nexus bento redesign (already iterated).
- New achievement definitions / DB taxonomy (UX only unless requested).

---

## Testing strategy

| When | What you do |
|------|-------------|
| **Now (optional)** | Smoke-test current `develop` APK only if you want — navigation/DM/league fixes from the pre-rebuild batch. Not required for sign-off. |
| **After Phase A–D** | **One manual device pass** on all three rebuilt screens (World, Identity, Achievements) using [DEVICE_UAT.md](../DEVICE_UAT.md) or the checklist below. |

We do **not** ask for full manual UAT after every small fix or after shell-only work — only after the **3-screen rebuild** is complete.

---

## Manual UAT checklist (after 3-screen rebuild)

### World info
- [ ] Collapsible hero expands on pull; scroll feels like one page (Reddit-style header + tabs)
- [ ] Feed / Channels / People / Manage (+ More for social) match split IA
- [ ] Join/leave, channels, members, settings still work

### Identity (Wall of Honour)
- [ ] Rank, tier, badges, worlds, achievements, perks visible without hunting
- [ ] Refresh stays on Identity; edit profile / share work
- [ ] Shortcuts (league, quests, settings) still reachable

### Achievements
- [ ] Category grid readable; proof upload (photo/gallery) works
- [ ] Pending / verified / rejected states clear
- [ ] Submit → back to category; verifier path unchanged for staff

### Regression (quick)
- [ ] Send DM / channel message — no kick to Nexus
- [ ] Search → Message — no white screen
- [ ] Nexus feed, chat, explore still usable

Report: device model, APK commit SHA, pass/fail per section.

---

## Source: `docs/archive/plans/SEASON-1-BIG-BANG.md`

# Season 1: The Big Bang

**Not** weekly league brackets. This is the first global season of Vertiege: empty worlds get occupied, councils and sovereigns emerge, and worlds grow through earned prestige.

## Product pillars

1. Unclaimed worlds find sovereigns  
2. Veteran councils emerge from standing  
3. World prestige unlocks lounge, treasury, governance  
4. Growth is earned, not purchased  

## Technical

- Client: [`lib/config/season_catalog.dart`](../../lib/config/season_catalog.dart), [`SeasonService`](../../lib/services/season_service.dart), [`SeasonScreen`](../../lib/screens/season_screen.dart)  
- DB: `global_seasons` row `season_1` in migration `20260530170000_season_1_big_bang.sql`  
- World challenges use `scope = 'world'` (season-scoped challenges later)

## Treasury (Season 1 rules)

Only **council** (5k+ rep) and **sovereign** may withdraw from treasury. No member withdrawal requests.

---

## Source: `docs/archive/plans/vertiege-claude-code-plan.md`

# Vertiege — Claude Code Implementation Plan

> Stack: Flutter + Riverpod + Supabase | Theme: Sovereign Excellence dark
> Use this document as your session guide in Claude Code. Each phase has a context block to paste at the start of every session, followed by specific tasks with suggested prompts.

---

## How to use this plan

1. Start a Claude Code session in your `vertiege/` project root
2. Paste the **Session Context** block at the top of each phase
3. Work through tasks one at a time using the suggested prompts
4. Check off tasks as you go

---

## Phase 1 — Foundation Fixes (Do these first)
*Estimated: 2–3 sessions | No new dependencies needed*

### Session Context (paste this at the start)
```
This is Vertiege, a Flutter + Riverpod + Supabase social app.
Theme: Sovereign Excellence dark (OLED obsidian, sovereign violet, gold tertiary).
Key files:
- lib/theme/colors.dart — AppColors
- lib/theme/design_system.dart — spacing, radius, animation tokens
- lib/models/ — all data models
- lib/services/ — all Supabase service calls
- lib/state/ — all Riverpod providers
- lib/screens/ — all screens
- lib/widgets/ — all reusable widgets
Always match the existing dark theme. Use GlassPanel, GlowBorder, TactileButton, GhostInput from lib/widgets/core/ wherever applicable.
```

### 1.1 — Markdown Rendering in Scrolls
- [ ] **Task:** Add flutter_markdown to pubspec and render message content in WorldChannelScreen and ChatRoomScreen
```
Add flutter_markdown to pubspec.yaml. In lib/screens/world_channel_screen.dart and lib/screens/chat_room_screen.dart, replace plain Text widgets for message content with a MarkdownBody widget. Style it to match AppColors: code blocks use the obsidian surface, links use sovereign violet. Keep it consistent with the existing chat bubble style.
```

### 1.2 — Read/Unread State per Zone
- [ ] **Task:** Track which channels a resident has read and show unread indicators
```
In lib/models/channel.dart, add a lastReadAt timestamp field. Create a Supabase table channel_reads (resident_id, channel_id, last_read_at). Update lib/services/chat_service.dart to mark a channel as read when the resident opens WorldChannelScreen. In lib/widgets/worlds/WorldChannelList, show an unread dot (use the existing StatusDot widget pattern) next to channels with unread messages.
```

### 1.3 — @AllResidents / @Rank Mention Broadcast
- [ ] **Task:** Wire up mention broadcasting so @AllResidents creates notifications
```
In lib/utils/text_parser.dart, the @mention extraction already exists. Extend it to detect @AllResidents and @NearbyResidents (active in last 30 min). When a message is posted in lib/services/chat_service.dart, if it contains @AllResidents, insert a notification row for all world members using notification_service.dart. Use NotificationType from lib/models/notification.dart — add a mention type if not present.
```

### 1.4 — Pinned Notices
- [ ] **Task:** Allow Wardens to pin Scrolls in any Gathering Spot
```
In lib/models/message.dart, add a bool isPinned field. In lib/services/chat_service.dart, add pinMessage(channelId, messageId) and fetchPinnedMessages(channelId) methods using Supabase. In lib/screens/world_channel_screen.dart, add a long-press context menu on messages (for Sovereign/Council ranks only via permission_service.dart) with a Pin option. Add a pinned messages panel at the top of the channel view using GlassPanel widget.
```

---

## Phase 2 — Social Graph (Companions & Bond Requests)
*Estimated: 2 sessions | No new dependencies*

### Session Context (paste this at the start)
```
This is Vertiege, a Flutter + Riverpod + Supabase social app.
I'm implementing the Companions (friends) system. Key existing files:
- lib/models/resident.dart — Resident model
- lib/services/chat_service.dart — DM logic
- lib/screens/chat_list_screen.dart — DM list
- lib/state/resident_provider.dart — resident state
- lib/screens/resident_profile_screen.dart — other resident's profile
- lib/widgets/core/ — GlassPanel, TactileButton, GhostInput etc.
Always match the Sovereign Excellence dark theme.
```

### 2.1 — Companions Data Layer
- [ ] **Task:** Create the friendships table and service
```
Create lib/models/companion.dart with fields: id, requesterId, receiverId, status (pending/accepted/blocked), createdAt. Create lib/services/companion_service.dart with methods: sendBondRequest(residentId), acceptBondRequest(requestId), declineBondRequest(requestId), blockResident(residentId), fetchCompanions(), fetchPendingRequests(). Create the corresponding Supabase table companions with a unique constraint on (requester_id, receiver_id).
```

### 2.2 — Companions Provider
- [ ] **Task:** Wire up Riverpod state
```
Create lib/state/companion_provider.dart using Riverpod. It should expose: companionsProvider (list of accepted companions with their Resident data), pendingRequestsProvider (incoming bond requests), and methods to send/accept/decline/block. Mirror the pattern in lib/state/chat_provider.dart for real-time subscriptions using Supabase channels.
```

### 2.3 — Bond Request UI on Profiles
- [ ] **Task:** Add send/accept/decline buttons to ResidentProfileScreen
```
In lib/screens/resident_profile_screen.dart, add a Bond Request button using TactileButton. Show three states: "Send Bond Request" (no relationship), "Bond Pending" (request sent), "Companions" (accepted). Use companion_provider.dart to drive the state. On the IdentityScreen (/identity), add a Companions tab showing the companions list from companionsProvider, using the existing glass card pattern from ChatListScreen.
```

### 2.4 — Bond Request Notifications
- [ ] **Task:** Notify residents of incoming requests
```
In lib/services/companion_service.dart, when sendBondRequest() is called, insert a row into the notifications table for the receiver using notification_service.dart. Add a new NotificationType.bondRequest in lib/models/notification.dart. In lib/screens/alerts_screen.dart, render bondRequest notifications with Accept/Decline action buttons inline (using TactileButton, small variant).
```

---

## Phase 3 — Channels Overhaul (Districts + Threads)
*Estimated: 3 sessions | No new dependencies*

### Session Context (paste this at the start)
```
This is Vertiege, a Flutter + Riverpod + Supabase social app.
I'm overhauling the channel system to add Districts (categories) and Side Alleys (threads).
Key existing files:
- lib/models/channel.dart — WorldChannel, ChannelType
- lib/services/chat_service.dart + lib/state/channel_provider.dart
- lib/widgets/worlds/WorldChannelList.dart
- lib/screens/world_channel_screen.dart + world_settings_screen.dart
Always match the Sovereign Excellence dark theme.
```

### 3.1 — Districts (Channel Categories)
- [ ] **Task:** Add category grouping to channels
```
In lib/models/channel.dart, add a nullable districtId field and districtName. Create a District model with id, worldId, name, position. Add a districts table in Supabase. Update lib/services/chat_service.dart to fetch channels grouped by district. In lib/widgets/worlds/WorldChannelList, render collapsible district headers (use FadeIn + GlassPanel). In lib/screens/world_settings_screen.dart, add District management (create/rename/delete/reorder) for the Sovereign.
```

### 3.2 — Side Alleys (Threads)
- [ ] **Task:** Add threaded replies to messages
```
In lib/models/message.dart, add threadId (nullable), threadCount (int), isThreadStarter (bool). Create a method in lib/services/chat_service.dart: fetchThreadMessages(threadId) and createThreadReply(parentMessageId, content). Create lib/screens/thread_screen.dart showing the parent message at the top (in a GlassPanel) and thread replies below, with a ChatInputBar at the bottom. In lib/screens/world_channel_screen.dart, add a "Reply in Side Alley" option to the message long-press menu. Show a thread count chip on messages that have replies.
```

### 3.3 — Herald's Board (Announcement Channel)
- [ ] **Task:** Enforce announcement-only posting rules
```
In lib/models/channel.dart, ChannelType.announcement already exists. In lib/services/chat_service.dart, add permission check: only residents with Sovereign or Council standing can post in announcement channels (check via permission_service.dart). In lib/widgets/worlds/WorldChannelList, render announcement channels with a distinct megaphone icon (use world icon map in design_system.dart). In WorldChannelScreen, show a "Read-only for your rank" banner at the bottom for non-moderators using ErrorBanner widget.
```

---

## Phase 4 — Custom Ranks & Edicts (Roles)
*Estimated: 2–3 sessions | No new dependencies*

### Session Context (paste this at the start)
```
This is Vertiege, a Flutter + Riverpod + Supabase social app.
I'm implementing custom Ranks (roles) with Edicts (permissions) per World.
Key existing files:
- lib/services/permission_service.dart — standing-based permissions
- lib/models/resident.dart — WorldStanding
- lib/screens/world_settings_screen.dart — sovereign management panel
- lib/screens/world_members_screen.dart — member roster
Always match the Sovereign Excellence dark theme. Keep the existing tier/standing system intact; custom Ranks are a separate layer on top.
```

### 4.1 — Rank Data Layer
- [ ] **Task:** Create the ranks system in Supabase and Flutter
```
Create lib/models/rank.dart with: id, worldId, name, color (hex), isHoisted, isMentionable, position, edicts (Map<String, bool> of permission flags). Create a world_ranks table in Supabase. Create lib/services/rank_service.dart with: createRank(), updateRank(), deleteRank(), fetchWorldRanks(worldId), assignRank(residentId, rankId), removeRank(residentId, rankId). Create a resident_ranks join table in Supabase.
```

### 4.2 — Rank Management UI
- [ ] **Task:** Build rank editor in WorldSettingsScreen
```
In lib/screens/world_settings_screen.dart, add a Ranks section. Show existing ranks as drag-reorderable tiles (use Flutter's ReorderableListView). Each tile shows a color swatch, rank name, and member count. Add a Create Rank button that opens a GlassSheet bottom sheet with: GhostInput for name, color picker (use a row of color swatches from AppColors tier accents), toggle switches for isHoisted and isMentionable, and a list of Edict toggles (50+ permissions as grouped toggle rows). Use TactileButton for save.
```

### 4.3 — Rank Assignment in Members Screen
- [ ] **Task:** Let the Sovereign assign Ranks to members
```
In lib/screens/world_members_screen.dart, add a long-press or tap action on member rows that opens a GlassSheet showing the member's current Ranks (as colored chips) and a list of all world Ranks to assign/remove. Fetch ranks via rank_service.dart. Show the resident's Ranks as colored chips in their member row (up to 3, then "+N more"). Update lib/screens/resident_profile_screen.dart to also show their Ranks for the current World context.
```

---

## Phase 5 — Voice Campfires (WebRTC)
*Estimated: 4–5 sessions | Requires new dependencies*

### Session Context (paste this at the start)
```
This is Vertiege, a Flutter + Riverpod + Supabase social app.
I'm implementing voice Campfires using LiveKit for WebRTC.
New dependencies to add: livekit_client, permission_handler.
Key existing files:
- lib/models/channel.dart — ChannelType (voice type exists)
- lib/services/chat_service.dart — channel message management
- lib/screens/world_channel_screen.dart
- lib/widgets/core/ — GlassPanel, GlowBorder, TactileButton, StatusDot
LiveKit server URL will be in .env as LIVEKIT_URL. Token generation happens server-side via a Supabase Edge Function.
Always match the Sovereign Excellence dark theme.
```

### 5.1 — Supabase Edge Function for LiveKit Token
- [ ] **Task:** Create server-side token generation
```
Create a Supabase Edge Function at supabase/functions/livekit-token/index.ts. It should accept { roomName, participantIdentity } in the request body, validate the caller is authenticated (check Supabase JWT), then use the LiveKit Server SDK to generate and return a JWT access token. Store LIVEKIT_API_KEY and LIVEKIT_API_SECRET as Supabase secrets.
```

### 5.2 — LiveKit Service in Flutter
- [ ] **Task:** Create the voice service layer
```
Add livekit_client and permission_handler to pubspec.yaml. Create lib/services/voice_service.dart with: joinCampfire(channelId, residentId) — fetches token from the Edge Function then connects to LiveKit room, leaveCampfire(), toggleMute(), toggleDeafen(), fetchCampfireParticipants(channelId). Create lib/state/voice_provider.dart exposing: currentRoomProvider (LiveKit Room?), participantsProvider, isMutedProvider, isDeafenedProvider.
```

### 5.3 — Campfire Participant UI
- [ ] **Task:** Build the voice channel view
```
Create lib/screens/campfire_screen.dart. Layout: top section shows Campfire name and World name. Middle: a grid of participant tiles (each showing CosmeticAvatar, LuminaryNameplate, a speaking indicator — pulsing GlowBorder when audio is active, muted icon overlay when muted). Bottom: a control bar with TactileButton icons for: Mute/Unmute, Deafen/Undeafen, Leave (red). Connect all controls to voice_provider.dart. Use GlassPanel for the overall container.
```

### 5.4 — Campfire Entry in Channel List
- [ ] **Task:** Join voice channels from the channel list
```
In lib/widgets/worlds/WorldChannelList, render voice channels (ChannelType.voice) differently from text channels: show a campfire icon, and below the channel name show small avatar stacks of current participants (fetch from voice_provider). Tapping a voice channel navigates to CampfireScreen instead of WorldChannelScreen. Show a "connected" indicator on voice channels the resident is currently in.
```

### 5.5 — Persistent Voice Status Bar
- [ ] **Task:** Show active voice session while browsing other screens
```
In lib/app.dart or TabLayout, add a persistent mini-bar at the bottom (above the tab bar) that appears when voice_provider has an active room. Show: Campfire name, mute toggle, and a Leave button. This bar persists while the resident navigates to other screens. Use GlassPanel with a subtle violet border. Tapping it navigates back to CampfireScreen.
```

---

## Phase 6 — Push Heralds (Push Notifications)
*Estimated: 1–2 sessions*

### Session Context (paste this at the start)
```
This is Vertiege, a Flutter + Riverpod + Supabase social app.
I'm adding push notifications using Firebase Cloud Messaging (FCM).
Existing: crash_reporter.dart already has Firebase scaffolding.
Key files: lib/services/notification_service.dart, lib/models/notification.dart (9 notification types).
```

### 6.1 — FCM Setup
- [ ] **Task:** Add FCM and request permissions
```
Add firebase_messaging and flutter_local_notifications to pubspec.yaml. In lib/main.dart, after Supabase init, initialize Firebase and FirebaseMessaging. Request notification permission using permission_handler. Get the FCM token and save it to the Supabase profiles table (add a fcm_token column). Create lib/services/push_service.dart handling: foreground messages (show local notification), background messages (via onBackgroundMessage handler), notification tap routing (use app_router.dart to navigate to the right screen based on notification payload).
```

### 6.2 — Server-Side Push Trigger
- [ ] **Task:** Send pushes from Supabase when notifications are created
```
Create a Supabase Database Webhook (or Edge Function triggered on notifications table INSERT). For each new notification row, look up the target resident's fcm_token from profiles, then send a FCM message via the Firebase Admin SDK. Map each NotificationType to an appropriate title/body template (e.g. bondRequest → "New Bond Request from {name}", mention → "{name} mentioned you in {worldName}"). Store FCM_SERVER_KEY as a Supabase secret.
```

---

## Phase 7 — Audit Log & Warden Tools
*Estimated: 1 session*

### Session Context (paste this at the start)
```
This is Vertiege, a Flutter + Riverpod + Supabase social app.
I'm building the Chronicle of Justice (audit log) and bulk message deletion.
Key files: lib/services/moderation_service.dart, lib/screens/world_settings_screen.dart, lib/models/report.dart.
```

### 7.1 — Chronicle of Justice (Audit Log)
- [ ] **Task:** Log all moderation actions and display them
```
Create a world_audit_log table in Supabase with: id, worldId, actorId, targetId (nullable), action (enum: ban, unban, kick, mute, unmute, deleteMessage, editChannel, createRank etc.), details (jsonb), createdAt. In lib/services/moderation_service.dart, insert an audit row after every moderation action. Create lib/screens/audit_log_screen.dart showing a scrollable list of audit entries grouped by date (use ChatDateSeparator widget). Each row shows: actor avatar, action description, target name, timestamp via TimeAgo. Add navigation to it from WorldSettingsScreen, gated to Sovereign/Council only.
```

### 7.2 — Bulk Message Deletion
- [ ] **Task:** Add purge command for Wardens
```
In lib/screens/world_channel_screen.dart, add a long-press selection mode for messages (Warden+ only, checked via permission_service.dart). When in selection mode, show checkboxes on each message and a "Delete Selected" action bar at the top (count of selected + delete button in red using AppColors danger). In lib/services/chat_service.dart, add bulkDeleteMessages(List<String> messageIds) using a Supabase batch delete. Log the bulk delete in audit_log after completion.
```

---

## Phase 8 — OAuth & Security Polish
*Estimated: 1 session*

### Session Context (paste this at the start)
```
This is Vertiege, a Flutter + Riverpod + Supabase social app.
I'm adding OAuth login (Google/Apple) and 2FA (Double Lock).
Key files: lib/services/auth_service.dart, lib/screens/auth/login_screen.dart, lib/screens/settings_screen.dart.
Supabase handles OAuth via its built-in providers.
```

### 8.1 — Google & Apple Sign In
- [ ] **Task:** Add OAuth buttons to LoginScreen
```
Add google_sign_in and sign_in_with_apple to pubspec.yaml. In lib/services/auth_service.dart, add signInWithGoogle() and signInWithApple() methods using Supabase's signInWithOAuth. In lib/screens/auth/login_screen.dart, add "Continue with Google" and "Continue with Apple" TactileButton variants below the existing email form, separated by an "or" divider. Style them to match the dark theme (white text on glass surface, provider logo icon).
```

### 8.2 — Double Lock (TOTP 2FA)
- [ ] **Task:** Add 2FA setup in settings
```
Add otp to pubspec.yaml for TOTP generation/verification. In lib/screens/settings_screen.dart, add a "Double Lock (2FA)" section. When enabling: generate a TOTP secret, display it as a QR code (use qr_flutter package) and as plain text backup. Ask the user to enter a 6-digit code to confirm setup. Store the secret encrypted via secure_storage_service.dart. On subsequent logins in lib/screens/auth/login_screen.dart, after password auth succeeds, check if 2FA is enabled and prompt for the 6-digit TOTP code before completing login.
```

---

## Supabase Tables Checklist

Track which tables you still need to create:

| Table | Phase | Done |
|---|---|---|
| `channel_reads` | 1.2 | [ ] |
| `companions` | 2.1 | [ ] |
| `districts` | 3.1 | [ ] |
| `world_ranks` | 4.1 | [ ] |
| `resident_ranks` | 4.1 | [ ] |
| `world_audit_log` | 7.1 | [ ] |
| `fcm_tokens` (column on profiles) | 6.1 | [ ] |

---

## Flutter Packages to Add (by phase)

| Package | Phase | Purpose |
|---|---|---|
| `flutter_markdown` | 1.1 | Render markdown in messages |
| `livekit_client` | 5 | WebRTC voice/video |
| `permission_handler` | 5 + 6 | Mic, camera, notification permissions |
| `firebase_messaging` | 6 | Push notifications |
| `flutter_local_notifications` | 6 | Foreground notification display |
| `google_sign_in` | 8.1 | Google OAuth |
| `sign_in_with_apple` | 8.2 | Apple OAuth |
| `qr_flutter` | 8.2 | TOTP QR code display |
| `otp` | 8.2 | TOTP generation/verification |

---

## Tips for Claude Code Sessions

- **Always paste the Session Context block first** — it gives Claude Code the file map so it edits the right files
- **One task per message** — don't batch multiple tasks; let Claude Code finish and test each one
- **Reference existing widgets** — remind Claude Code to use `GlassPanel`, `TactileButton`, `GhostInput` etc. so the UI stays consistent
- **After each task, run:** `flutter analyze` to catch type errors before moving on
- **For Supabase schema changes**, ask Claude Code to generate the SQL migration too, not just the Flutter model
- **Voice (Phase 5) is the hardest** — budget extra time and don't skip 5.1 (the Edge Function) before 5.2

---

*Generated for Vertiege — 191 Dart files, Flutter + Riverpod + Supabase*

---

## Source: `docs/archive/root-plans/2026-05-19/implementation.md`

# Vertiege Implementation Plan & Vision Alignment

This document outlines the roadmap to align the Vertiege application with the intended product vision. It serves as a persistent guide for AI agents and developers.

## Vision Overview
Vertiege is a highly gamified, exclusive, tier-gated social network. The core loop involves:
1. **Onboarding**: Users register, state an occupation, start unverified, and get access to starter worlds.
2. **Progression**: Users submit real-world proof to verify their occupation. They earn XP to level up their Tier (class).
3. **Exclusivity**: Users unlock "Wealth Worlds" by reaching a high enough Tier, or by buying their way in. Verified users get access to exclusive Occupation Worlds.
4. **Sovereignty**: High-level users unlock the ability to create their own worlds and become a Sovereign.
5. **Monetization**: Users can spend Sovereign Coins in the shop for XP boosters, new features (extra world slots), and cosmetics.

## Current Status & Roadmap

### Phase 1: Verification & Admin Tools [✅ COMPLETED]
- **Status:** Done
- **Work Completed:**
  - Updated `VerificationService.approve` to automatically assign the `verified_roles` to the user's database entry.
  - Exposed the hidden `VerificationReviewScreen` as an Admin Dashboard accessible from the Profile Screen (restricted to users named 'Immabe', 'Creator', or 'Admin').

### Phase 2: Starter Worlds Auto-Join [✅ COMPLETED]
- **Status:** Done
- **Gap:** The database supports `is_default` for worlds, but the onboarding flow never joins new users to them. Users wake up to an empty feed.
- **Implementation:**
  - Modified `lib/screens/onboarding/onboarding_screen.dart` to fetch worlds where `isDefault == true` instead of relying on hardcoded slugs.
  - The resident provider already handles joining these worlds automatically upon resident creation.

### Phase 3: Wealth World Level-Up Access [✅ COMPLETED]
- **Status:** Done
- **Gap:** The app forces users to buy their way into Wealth Worlds via In-App Purchases, even if their `ResidentTier` qualifies them.
- **Implementation:**
  - Verified `canAccessWorld` already successfully grants free access if `resident.tier >= world.requiredTier`.
  - The gap was in the UI. Updated `WorldAccessGuard` to display a detailed progress breakdown comparing the user's current Tier vs the Required Tier, and explicitly stating they can level up via XP to enter for free, rather than presenting a hard paywall.

### Phase 4: Sovereign Level-Gate [✅ COMPLETED]
- **Status:** Done
- **Gap:** The required level for world creation was too low (Tier 2 - High Roller, 500 XP), allowing early accounts to create worlds instantly.
- **Implementation:**
  - Updated `CreateWorldScreen` (`lib/screens/create_world_screen.dart`).
  - Increased the gate to require Tier 3 (Elite) and 2000 XP to make world creation a meaningful mid-to-late game milestone.

### Phase 5: Real-World Achievements & Shop Expansions [✅ COMPLETED]
- **Status:** Done
- **Gap:** No way to submit proof for real-world achievements. Shop only has cosmetics, lacking XP boosters and feature unlocks.
- **Implementation:**
  - Wired up the orphaned `SubmitAchievementScreen` by adding a "Submit Proof" Floating Action Button to the Achievements index.
  - Added new "Extra World Slot" and "2x XP Boost" items to the Cosmetics Shop (under the Seeds and Boosts tabs) purchasable with in-game Sovereign Coins.

---
*Note: Agents should update the status tags in this file as work is completed.*

---
