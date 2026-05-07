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

  // ── Achievement Category Colors ───────────────────────────
  static const Color achievementEducation = Color(0xFF4A90D9);
  static const Color achievementCareer = Color(0xFF7B61FF);
  static const Color achievementRelationships = Color(0xFFE8456B);
  static const Color achievementHealth = Color(0xFF3ECF8E);
  static const Color achievementSkills = Color(0xFFF0B232);
  static const Color achievementTravel = Color(0xFF1CB0F6);
  static const Color achievementFinance = Color(0xFF58CC02);
  static const Color achievementCommunity = Color(0xFFFF9600);
  static const Color achievementFunny = Color(0xFFCE82FF);
  static const Color achievementCreative = Color(0xFFFF5764);
  static const Color achievementProfession = Color(0xFFD4A843);

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
  static const Color owlGreen = Color(0xFF58CC02);
  static const double glowAlpha = 0.15;
  static const Color gemPink = Color(0xFFEC4899);
  static const Color beeYellow = Color(0xFFFFC800);
  static const Color eelBlue = Color(0xFF1CB0F6);
  static const Color crimson = Color(0xFF8B2252);
  static const Color dangerRed = error;
  static const Color gold = tertiary;
  static const Color silver = Color(0xFFC0C0C0);
  static const Color bronze = Color(0xFFCD7F32);
  static const Color mysticBlue = Color(0xFF5865F2);
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
