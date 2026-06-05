import 'package:flutter/material.dart';

/// Discord-style dark surface ladder for Commune chat surfaces.
/// See docs/reference/DESIGN.md.
abstract final class VCommuneColors {
  static const Color surfacePrimary = Color(0xFF313338);
  static const Color surfaceSecondary = Color(0xFF2B2D31);
  static const Color surfaceSecondaryAlt = Color(0xFF232428);
  static const Color surfaceTertiary = Color(0xFF1E1F22);
  static const Color surfaceFloating = Color(0xFF111214);
  static const Color textNormal = Color(0xFFDBDEE1);
  static const Color textMuted = Color(0xFF949BA4);
  static const Color headerPrimary = Color(0xFFF2F3F5);
  static const Color headerSecondary = Color(0xFFB5BAC1);
  static const Color textLink = Color(0xFF00A8FC);

  // Interactive modifiers (on dark surfaces)
  static Color modifierHover = const Color(0xFF4F545C).withValues(alpha: 0.16);
  static Color modifierActive = const Color(0xFF4F545C).withValues(alpha: 0.24);
  static Color modifierSelected = const Color(0xFF4F545C).withValues(alpha: 0.32);

  // Status
  static const Color statusOnline = Color(0xFF23A55A);
  static const Color statusIdle = Color(0xFFF0B232);
  static const Color statusDnd = Color(0xFFF23F43);
  static const Color statusOffline = Color(0xFF80848E);

  // Dividers
  static Color dividerSubtle = Colors.white.withValues(alpha: 0.06);
}
