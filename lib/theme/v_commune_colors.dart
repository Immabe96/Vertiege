import 'package:flutter/material.dart';

import 'v_colors.dart';

/// Discord-style surface ladder for Commune chat surfaces.
/// See docs/reference/DESIGN.md.
abstract final class VCommuneColors {
  // --- Dark ladder (Snapchat-pure black) ---
  static const Color surfacePrimary = Color(0xFF121212);
  static const Color surfaceSecondary = Color(0xFF1A1A1A);
  static const Color surfaceSecondaryAlt = Color(0xFF222222);
  static const Color surfaceTertiary = Color(0xFF0A0A0A);
  static const Color surfaceFloating = Color(0xFF000000);
  static const Color textNormal = Color(0xFFDBDEE1);
  static const Color textMuted = Color(0xFF949BA4);
  static const Color headerPrimary = Color(0xFFF2F3F5);
  static const Color headerSecondary = Color(0xFFB5BAC1);
  static const Color textLink = Color(0xFF00A8FC);

  /// @mentions — brand accent, not link blue.
  static const Color textMention = VColors.brand;

  // --- Light ladder (Snapchat-clean white) ---
  static const Color surfacePrimaryLight = Color(0xFFFFFFFF);
  static const Color surfaceSecondaryLight = Color(0xFFF5F5F5);
  static const Color surfaceSecondaryAltLight = Color(0xFFEEEEEE);
  static const Color surfaceTertiaryLight = Color(0xFFE5E5E5);
  static const Color surfaceFloatingLight = Color(0xFFE0E0E0);
  static const Color textNormalLight = Color(0xFF000000);
  static const Color textMutedLight = Color(0xFF666666);
  static const Color headerPrimaryLight = Color(0xFF000000);
  static const Color headerSecondaryLight = Color(0xFF444444);
  static const Color textLinkLight = Color(0xFF006CE7);

  // Interactive modifiers (on dark surfaces)
  static Color modifierHover = const Color(0xFF4F545C).withValues(alpha: 0.16);
  static Color modifierActive = const Color(0xFF4F545C).withValues(alpha: 0.24);
  static Color modifierSelected = const Color(0xFF4F545C).withValues(alpha: 0.32);

  static Color modifierHoverLight =
      const Color(0xFF4F545C).withValues(alpha: 0.08);
  static Color modifierActiveLight =
      const Color(0xFF4F545C).withValues(alpha: 0.12);
  static Color modifierSelectedLight =
      const Color(0xFF4F545C).withValues(alpha: 0.16);

  // Status (unified presence dots)
  static const Color statusOnline = Color(0xFF23A55A);
  static const Color statusIdle = Color(0xFFF0B232);
  static const Color statusDnd = Color(0xFFF23F43);
  static const Color statusOffline = Color(0xFF80848E);

  /// Subtle 1px dividers — 10% white on dark (DCX-039).
  static Color dividerSubtle = Colors.white.withValues(alpha: 0.10);
  static Color dividerSubtleLight = Colors.black.withValues(alpha: 0.08);

  static Color surfacePrimaryOf(Brightness brightness) =>
      brightness == Brightness.dark ? surfacePrimary : surfacePrimaryLight;

  static Color textNormalOf(Brightness brightness) =>
      brightness == Brightness.dark ? textNormal : textNormalLight;

  static Color textMutedOf(Brightness brightness) =>
      brightness == Brightness.dark ? textMuted : textMutedLight;

  static Color headerPrimaryOf(Brightness brightness) =>
      brightness == Brightness.dark ? headerPrimary : headerPrimaryLight;

  static Color dividerOf(Brightness brightness) =>
      brightness == Brightness.dark ? dividerSubtle : dividerSubtleLight;

  static Color textLinkOf(Brightness brightness) =>
      brightness == Brightness.dark ? textLink : textLinkLight;

  static Color surfaceSecondaryOf(Brightness brightness) =>
      brightness == Brightness.dark ? surfaceSecondary : surfaceSecondaryLight;

  static Color surfaceSecondaryAltOf(Brightness brightness) =>
      brightness == Brightness.dark
          ? surfaceSecondaryAlt
          : surfaceSecondaryAltLight;

  static Color surfaceTertiaryOf(Brightness brightness) =>
      brightness == Brightness.dark ? surfaceTertiary : surfaceTertiaryLight;

  static Color headerSecondaryOf(Brightness brightness) =>
      brightness == Brightness.dark ? headerSecondary : headerSecondaryLight;
}
