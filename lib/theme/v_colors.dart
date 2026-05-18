import 'package:flutter/material.dart';

/// Vertiege Color System — Material 3 compatible
/// All colors are theme-aware via Theme.of(context).colorScheme
class VColors {
  VColors._();

  static const primary = Color(0xFF111111);
  static const primaryLight = Color(0xFFFFFFFF);
  static const primaryDark = Color(0xFF000000);
  static const primaryContainer = Color(0xFFF1F1F1);
  static const primaryContainerDark = Color(0xFF161616);
  static const onPrimary = Color(0xFFFFFFFF);
  static const onPrimaryContainer = Color(0xFF1A1C1C);
  static const onPrimaryContainerDark = Color(0xFFE8DFFF);

  static const secondary = Color(0xFF7C3AED);
  static const secondaryLight = Color(0xFFA78BFA);
  static const secondaryDark = Color(0xFF5B21B6);
  static const secondaryContainer = Color(0xFFF1EAFE);
  static const secondaryContainerDark = Color(0xFF211437);
  static const onSecondary = Color(0xFFFFFFFF);
  static const onSecondaryContainer = Color(0xFF25005A);
  static const onSecondaryContainerDark = Color(0xFFFFDF8E);

  static const tertiary = Color(0xFF007AFF);
  static const tertiaryLight = Color(0xFF64B5FF);
  static const tertiaryDark = Color(0xFF0062CC);
  static const tertiaryContainer = Color(0xFFEAF4FF);
  static const tertiaryContainerDark = Color(0xFF082033);
  static const onTertiary = Color(0xFFFFFFFF);
  static const onTertiaryContainer = Color(0xFF00325F);
  static const onTertiaryContainerDark = Color(0xFFFFD6EA);

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

  static const surface = Color(0xFFFFFFFF);
  static const surfaceDim = Color(0xFFF6F6F6);
  static const surfaceBright = Color(0xFFFFFFFF);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFFAFAFA);
  static const surfaceContainer = Color(0xFFF4F4F5);
  static const surfaceContainerHigh = Color(0xFFEDEDEE);
  static const surfaceContainerHighest = Color(0xFFE4E4E7);
  static const onSurface = Color(0xFF09090B);
  static const onSurfaceVariant = Color(0xFF52525B);
  static const outline = Color(0xFF71717A);
  static const outlineVariant = Color(0xFFE4E4E7);
  static const inverseSurface = Color(0xFF09090B);
  static const onInverseSurface = Color(0xFFFFFFFF);
  static const inversePrimary = Color(0xFFFFFFFF);

  static const surfaceDark = Color(0xFF000000);
  static const surfaceDimDark = Color(0xFF000000);
  static const surfaceBrightDark = Color(0xFF0A0A0A);
  static const surfaceContainerLowestDark = Color(0xFF000000);
  static const surfaceContainerLowDark = Color(0xFF050505);
  static const surfaceContainerDark = Color(0xFF0A0A0A);
  static const surfaceContainerHighDark = Color(0xFF111111);
  static const surfaceContainerHighestDark = Color(0xFF181818);
  static const onSurfaceDark = Color(0xFFFFFFFF);
  static const onSurfaceVariantDark = Color(0xFFA1A1AA);
  static const outlineDark = Color(0xFF52525B);
  static const outlineVariantDark = Color(0xFF27272A);
  static const inverseSurfaceLight = Color(0xFFFFFFFF);
  static const onInverseSurfaceDark = Color(0xFF000000);
  static const inversePrimaryDark = Color(0xFF000000);

  static const glassBackground = Color(0xFFFFFFFF);
  static const glassBorder = Color(0xFFE4E4E7);
  static const glassBackgroundDark = Color(0xFF0A0A0A);
  static const glassBorderDark = Color(0xFF27272A);

  static const gradientPrimary = LinearGradient(
    colors: [surfaceContainerLowest, surfaceContainerLow],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientBrand = LinearGradient(
    colors: [surfaceContainerLowest, primaryContainer],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientWarm = LinearGradient(
    colors: [surfaceContainerLowest, secondaryContainer],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientSunset = LinearGradient(
    colors: [surfaceContainerLowest, tertiaryContainer],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientOcean = LinearGradient(
    colors: [surfaceContainerLowest, Color(0xFFEAF5FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const dark = Color(0xFF0B0B1A);
  static const light = Color(0xFFF8F7FF);

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
