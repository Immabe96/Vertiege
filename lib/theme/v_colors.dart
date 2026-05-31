import 'package:flutter/material.dart';

/// Vertiege color system — Material 3 + Prestige Noir brand.
///
/// Accent roles:
/// - [brand] (tertiary): gold prestige — CTAs, Campfire, highlights
/// - [secondary]: violet — worlds, magic, creative UI
/// - [link]: blue — URLs and system-style links only
/// - [primary]: neutral chrome (ink on light / paper on dark)
class VColors {
  VColors._();

  static const primary = Color(0xFF111111);
  static const primaryLight = Color(0xFFFFFFFF);
  static const primaryDark = Color(0xFF000000);
  static const primaryContainer = Color(0xFFF1F1F1);
  static const primaryContainerDark = Color(0xFF1A1F2B);
  static const onPrimary = Color(0xFFFFFFFF);
  static const onPrimaryContainer = Color(0xFF1A1C1C);
  static const onPrimaryContainerDark = Color(0xFFE8E4DC);

  static const secondary = Color(0xFF7C3AED);
  static const secondaryLight = Color(0xFFA78BFA);
  static const secondaryDark = Color(0xFF5B21B6);
  static const secondaryContainer = Color(0xFFF1EAFE);
  static const secondaryContainerDark = Color(0xFF211437);
  static const onSecondary = Color(0xFFFFFFFF);
  static const onSecondaryContainer = Color(0xFF25005A);
  static const onSecondaryContainerDark = Color(0xFFE8DFFF);

  /// Prestige gold — primary brand accent (aliased as tertiary for M3 compat).
  static const brand = Color(0xFFC9A227);
  static const brandLight = Color(0xFFE4C04A);
  static const brandDark = Color(0xFF9A7B1A);
  static const brandContainer = Color(0xFFFFF8E8);
  static const brandContainerDark = Color(0xFF2A2410);
  static const onBrand = Color(0xFF1A1408);
  static const onBrandContainer = Color(0xFF3D2E08);
  static const onBrandContainerDark = Color(0xFFFFE9A8);

  static const tertiary = brand;
  static const tertiaryLight = brandLight;
  static const tertiaryDark = brandDark;
  static const tertiaryContainer = brandContainer;
  static const tertiaryContainerDark = brandContainerDark;
  static const onTertiary = onBrand;
  static const onTertiaryContainer = onBrandContainer;
  static const onTertiaryContainerDark = onBrandContainerDark;

  /// Hyperlinks and external actions — not brand chrome.
  static const link = Color(0xFF2563EB);
  static const linkDark = Color(0xFF6CB4FF);

  static const error = Color(0xFFEF4444);
  static const errorContainer = Color(0xFFFFEBEE);
  static const errorContainerDark = Color(0xFF6B1010);
  static const onError = Color(0xFFFFFFFF);
  static const onErrorContainer = Color(0xFF5C0A0A);
  static const onErrorContainerDark = Color(0xFFFFD6D6);

  static const success = Color(0xFF10B981);
  static const successContainer = Color(0xFFE0F5EC);
  static const successContainerDark = Color(0xFF0A4A35);
  static const onSuccessContainer = Color(0xFF0A3D2B);
  static const onSuccessContainerDark = Color(0xFF8EF0C8);

  static const warning = Color(0xFFF59E0B);
  static const warningContainer = Color(0xFFFFF8E1);
  static const warningContainerDark = Color(0xFF5C3D00);
  static const onWarningContainer = Color(0xFF4A2E00);
  static const onWarningContainerDark = Color(0xFFFFDF8E);

  static const surface = Color(0xFFFAFAF9);
  static const surfaceDim = Color(0xFFF4F4F3);
  static const surfaceBright = Color(0xFFFFFFFF);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFF7F7F6);
  static const surfaceContainer = Color(0xFFF0F0EF);
  static const surfaceContainerHigh = Color(0xFFE8E8E7);
  static const surfaceContainerHighest = Color(0xFFDCDCD9);
  static const onSurface = Color(0xFF0F1117);
  static const onSurfaceVariant = Color(0xFF52525B);
  static const outline = Color(0xFF71717A);
  static const outlineVariant = Color(0xFFE4E4E7);
  static const inverseSurface = Color(0xFF0F1117);
  static const onInverseSurface = Color(0xFFFFFFFF);
  static const inversePrimary = Color(0xFFFFFFFF);

  /// Prestige Noir dark — elevated charcoal (not pure AMOLED black).
  static const surfaceDark = Color(0xFF0F1117);
  static const surfaceDimDark = Color(0xFF0F1117);
  static const surfaceBrightDark = Color(0xFF141820);
  static const surfaceContainerLowestDark = Color(0xFF0F1117);
  static const surfaceContainerLowDark = Color(0xFF141820);
  static const surfaceContainerDark = Color(0xFF1A1F2B);
  static const surfaceContainerHighDark = Color(0xFF222836);
  static const surfaceContainerHighestDark = Color(0xFF2A3142);
  static const onSurfaceDark = Color(0xFFF4F4F5);
  static const onSurfaceVariantDark = Color(0xFFA1A1AA);
  static const outlineDark = Color(0xFF52525B);
  static const outlineVariantDark = Color(0xFF2A3142);
  static const inverseSurfaceLight = Color(0xFFFFFFFF);
  static const onInverseSurfaceDark = Color(0xFF0F1117);
  static const inversePrimaryDark = Color(0xFF0F1117);

  static const glassBackground = Color(0xFFFFFFFF);
  static const glassBorder = Color(0xFFE4E4E7);
  static const glassBackgroundDark = Color(0xFF1A1F2B);
  static const glassBorderDark = Color(0xFF2A3142);

  static const gradientPrimary = LinearGradient(
    colors: [surfaceContainerLowest, surfaceContainerLow],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientBrand = LinearGradient(
    colors: [brandContainer, surfaceContainerLowest],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientWarm = LinearGradient(
    colors: [surfaceContainerLowest, secondaryContainer],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientSunset = LinearGradient(
    colors: [surfaceContainerLowest, brandContainer],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientOcean = LinearGradient(
    colors: [surfaceContainerLowest, Color(0xFFEAF5FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const dark = Color(0xFF0F1117);
  static const light = Color(0xFFFAFAF9);

  static const tierHustler = Color(0xFFEF4444);
  static const tierHighRoller = Color(0xFF0EA5E9);
  static const tierElite = Color(0xFF7C3AED);
  static const tierOldMoney = Color(0xFFF59E0B);
  static const tierApex = Color(0xFFEC4899);

  static const online = Color(0xFF10B981);
  static const idle = Color(0xFFF59E0B);
  static const dnd = Color(0xFFEF4444);
  static const offline = Color(0xFF6B7280);

  static const achievementEducation = Color(0xFF3B82F6);
  static const achievementCareer = Color(0xFF10B981);
  static const achievementHealth = Color(0xFFEF4444);
  static const achievementFinance = Color(0xFFF59E0B);
  static const achievementSocial = Color(0xFFEC4899);
  static const achievementCreative = Color(0xFF8B5CF6);
  static const achievementAdventure = Color(0xFF0EA5E9);
  static const achievementLeadership = Color(0xFFF97316);
  static const achievementKnowledge = Color(0xFF6366F1);
  static const achievementWellness = Color(0xFF14B8A6);
  static const achievementSpecial = Color(0xFFA855F7);

  static const prestigeNone = Color(0xFF6B7280);
  static const prestigeBronze = Color(0xFFCD7F32);
  static const prestigeSilver = Color(0xFFC0C0C0);
  static const prestigeGold = Color(0xFFFFD700);
  static const prestigeApex = Color(0xFFEC4899);

  static const scrim = Color(0x80000000);
  static const scrimDark = Color(0x80000000);
  static const divider = outlineVariant;
  static const dividerDark = outlineVariantDark;
  static const skeleton = surfaceContainerHigh;
  static const skeletonDark = surfaceContainerHighDark;
}
