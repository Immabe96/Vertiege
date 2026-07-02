import 'package:flutter/material.dart';

import 'v_colors.dart';
import 'prestige_noir.dart';

/// Commune chat surface ladder — aligned with Prestige Noir (dark-only app).
abstract final class VCommuneColors {
  // --- Dark ladder (Prestige Noir) ---
  static const Color surfacePrimary = PrestigeNoir.bg;
  static const Color surfaceSecondary = PrestigeNoir.surface;
  static const Color surfaceSecondaryAlt = PrestigeNoir.surfaceRaised;
  static const Color surfaceTertiary = PrestigeNoir.chrome;
  static const Color surfaceFloating = PrestigeNoir.bg;
  static const Color textNormal = PrestigeNoir.foreground;
  static const Color textMuted = PrestigeNoir.muted;
  static const Color headerPrimary = PrestigeNoir.foreground;
  static const Color headerSecondary = PrestigeNoir.mutedDim;
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

  static Color surfacePrimaryOf(Brightness brightness) => surfacePrimary;

  static Color textNormalOf(Brightness brightness) => textNormal;

  static Color textMutedOf(Brightness brightness) => textMuted;

  static Color headerPrimaryOf(Brightness brightness) => headerPrimary;

  static Color dividerOf(Brightness brightness) => dividerSubtle;

  static Color textLinkOf(Brightness brightness) =>
      brightness == Brightness.dark ? textLink : textLinkLight;

  static Color surfaceSecondaryOf(Brightness brightness) => surfaceSecondary;

  static Color surfaceSecondaryAltOf(Brightness brightness) =>
      surfaceSecondaryAlt;

  static Color surfaceTertiaryOf(Brightness brightness) => surfaceTertiary;

  static Color headerSecondaryOf(Brightness brightness) => headerSecondary;
}
