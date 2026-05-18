import 'package:flutter/material.dart';
import 'v_colors.dart';
export 'v_colors.dart';

/// Backward-compatible aliases — all point to new VColors
/// TODO: Migrate all usages to VColors directly, then remove this file
class AppColors {
  AppColors._();

  static const primary = VColors.primary;
  static const primaryLight = VColors.primaryLight;
  static const primaryDark = VColors.primaryDark;
  static const primaryContainer = VColors.primaryContainer;
  static const onPrimary = VColors.onPrimary;
  static const onPrimaryContainer = VColors.onPrimaryContainer;

  static const secondary = VColors.secondary;
  static const secondaryLight = VColors.secondaryLight;
  static const secondaryDark = VColors.secondaryDark;
  static const secondaryContainer = VColors.secondaryContainer;
  static const onSecondary = VColors.onSecondary;
  static const onSecondaryContainer = VColors.onSecondaryContainer;

  static const tertiary = VColors.tertiary;
  static const tertiaryLight = VColors.tertiaryLight;
  static const tertiaryDark = VColors.tertiaryDark;
  static const tertiaryContainer = VColors.tertiaryContainer;
  static const tertiaryFixedDim = VColors.tertiaryContainer;
  static const tertiaryFixed = VColors.tertiary;
  static const onTertiary = VColors.onTertiary;
  static const onTertiaryContainer = VColors.onTertiaryContainer;

  static const error = VColors.error;
  static const errorContainer = VColors.errorContainer;
  static const onError = VColors.onError;
  static const onErrorContainer = VColors.onErrorContainer;

  static const success = VColors.success;
  static const semanticSuccess = VColors.success;
  static const semanticError = VColors.error;
  static const successContainer = VColors.successContainer;

  static const warning = VColors.warning;
  static const warningContainer = VColors.warningContainer;

  static const canvas = VColors.surface;
  static const surface = VColors.surface;
  static const surfaceElevated = VColors.surfaceBright;
  static const surfaceOverlay = VColors.surfaceContainerHigh;
  static const surfaceHigh = VColors.surfaceContainerHighest;
  static const surfaceContainerLowest = VColors.surfaceContainerLowest;
  static const surfaceContainerLow = VColors.surfaceContainerLow;
  static const surfaceContainer = VColors.surfaceContainer;
  static const surfaceContainerHigh = VColors.surfaceContainerHigh;
  static const surfaceContainerHighest = VColors.surfaceContainerHighest;

  static const glassBackground = VColors.glassBackground;
  static const glassBorder = VColors.glassBorder;
  static const glassModalBackground = VColors.glassBackground;

  static const ink = VColors.onSurface;
  static const inkSecondary = VColors.onSurfaceVariant;
  static const inkMuted = VColors.outline;
  static const inkOnAccent = VColors.onPrimary;

  static const borderDefault = VColors.outline;
  static const borderSubtle = VColors.outlineVariant;
  static const outline = VColors.outline;
  static const outlineVariant = VColors.outlineVariant;

  static const dark = VColors.dark;
  static const light = VColors.light;

  static const hustler = VColors.tierHustler;
  static const highRoller = VColors.tierHighRoller;
  static const elite = VColors.tierElite;
  static const oldMoney = VColors.tierOldMoney;
  static const apex = VColors.tierApex;

  static const online = VColors.online;
  static const idle = VColors.idle;
  static const dnd = VColors.dnd;
  static const offline = VColors.offline;

  static const owlGreen = VColors.achievementEducation;
  static const gemPink = VColors.achievementSocial;
  static const beeYellow = VColors.achievementFinance;
  static const eelBlue = VColors.achievementAdventure;
  static const crimson = VColors.tierHustler;
  static const gold = VColors.tierOldMoney;
  static const silver = VColors.outline;
  static const bronze = VColors.outlineVariant;
  static const mysticBlue = VColors.primary;

  static const tier1 = VColors.tierHustler;
  static const tier2 = VColors.tierHighRoller;
  static const tier3 = VColors.tierElite;
  static const tier4 = VColors.tierOldMoney;
  static const tier5 = VColors.tierApex;
  static const tierHustler = VColors.tierHustler;
  static const tierHighRoller = VColors.tierHighRoller;
  static const tierElite = VColors.tierElite;
  static const tierOldMoney = VColors.tierOldMoney;
  static const tierApex = VColors.tierApex;

  static const achievementEducation = VColors.achievementEducation;
  static const achievementCareer = VColors.achievementCareer;
  static const achievementHealth = VColors.achievementHealth;
  static const achievementFinance = VColors.achievementFinance;
  static const achievementSocial = VColors.achievementSocial;
  static const achievementCreative = VColors.achievementCreative;
  static const achievementAdventure = VColors.achievementAdventure;
  static const achievementLeadership = VColors.achievementLeadership;
  static const achievementKnowledge = VColors.achievementKnowledge;
  static const achievementWellness = VColors.achievementWellness;
  static const achievementSpecial = VColors.achievementSpecial;
  static const achievementRelationships = VColors.achievementSocial;
  static const achievementSkills = VColors.achievementKnowledge;
  static const achievementTravel = VColors.achievementAdventure;
  static const achievementCommunity = VColors.achievementSocial;
  static const achievementFunny = VColors.achievementCreative;
  static const achievementProfession = VColors.achievementCareer;

  static const accentLevel = VColors.primary;
  static const accentStreak = VColors.secondary;
  static const accentAchievement = VColors.tertiary;
  static const accentPrestige = VColors.tierElite;

  static const primaryFixedDim = VColors.primaryContainer;
  static const primaryFixed = VColors.primary;

  static const dangerRed = VColors.error;

  static const glowGoldAlpha = 0.3;
  static const glowVioletAlpha = 0.3;
  static const glowOrangeAlpha = 0.3;
  static const glowAlphaStrong = 0.5;

  static const gradientPrimary = VColors.gradientPrimary;
  static const gradientBrand = VColors.gradientBrand;
  static const gradientWarm = VColors.gradientWarm;
  static const gradientDark = LinearGradient(
    colors: [Color(0xFF1A1A2E), Color(0xFF0B0B1A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const gradientLight = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF0EEF8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const gradientSunset = VColors.gradientSunset;
  static const gradientOcean = VColors.gradientOcean;

  static const alphaHover = 0.08;
  static const alphaPressed = 0.12;
  static const alphaSelected = 0.16;
  static const alphaBorder = 0.2;
  static const alphaOverlay = 0.5;

  static Color resolveCanvas({bool dark = false}) =>
      dark ? VColors.surfaceDark : surface;
  static Color resolveSurface({bool dark = false}) =>
      dark ? VColors.surfaceDark : surface;
  static Color resolveSurfaceContainer({bool dark = false}) =>
      dark ? VColors.surfaceContainerDark : surfaceContainer;
  static Color resolveSurfaceContainerLow({bool dark = false}) =>
      dark ? VColors.surfaceContainerLowDark : surfaceContainerLow;
  static Color resolveSurfaceContainerHigh({bool dark = false}) =>
      dark ? VColors.surfaceContainerHighDark : surfaceContainerHigh;
  static Color resolveSurfaceContainerHighest({bool dark = false}) =>
      dark ? VColors.surfaceContainerHighestDark : surfaceContainerHighest;
  static Color resolveGlassBackground({bool dark = false}) =>
      dark ? VColors.glassBackgroundDark : glassBackground;
  static Color resolveGlassBorder({bool dark = false}) =>
      dark ? VColors.glassBorderDark : glassBorder;
  static Color resolveInk({bool dark = false}) =>
      dark ? VColors.onSurfaceDark : ink;
  static Color resolveInkSecondary({bool dark = false}) =>
      dark ? VColors.onSurfaceVariantDark : inkSecondary;
  static Color resolveInkMuted({bool dark = false}) =>
      dark ? VColors.outlineDark : inkMuted;
  static Color resolveBorderDefault({bool dark = false}) =>
      dark ? VColors.outlineDark : borderDefault;
  static Color resolveBorderSubtle({bool dark = false}) =>
      dark ? VColors.outlineVariantDark : borderSubtle;
  static Color resolvePrimary({bool dark = false}) =>
      dark ? VColors.primaryLight : primary;
  static Color resolveSecondary({bool dark = false}) =>
      dark ? VColors.secondaryLight : secondary;
  static Color resolveTertiary({bool dark = false}) =>
      dark ? VColors.tertiaryLight : tertiary;
}
