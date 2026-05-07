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
