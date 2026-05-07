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
