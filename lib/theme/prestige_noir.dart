import 'package:flutter/material.dart';

/// Open Design Prestige Noir palette (`mobile-ios.html` :root).
///
/// Single visual system for Vertiege — dark-only, cool-tinted surfaces,
/// gold accent discipline. Values are hex approximations of the prototype oklch tokens.
abstract final class PrestigeNoir {
  /// oklch(7% 0.006 260) — app background
  static const bg = Color(0xFF101114);

  /// oklch(9% 0.008 260) — tab bar, world rail
  static const chrome = Color(0xFF14171C);

  /// oklch(11% 0.008 260) — cards, panels
  static const surface = Color(0xFF171A1F);

  /// oklch(14% 0.01 260) — raised bento / hero cards
  static const surfaceRaised = Color(0xFF1F2329);

  /// oklch(91% 0.005 260) — primary text
  static const foreground = Color(0xFFE6E7EB);

  /// oklch(52% 0.012 260) — secondary / muted text
  static const muted = Color(0xFF7B8089);

  /// oklch(35% 0.01 260) — dim labels, section headers
  static const mutedDim = Color(0xFF53575F);

  /// oklch(20% 0.008 260) — borders
  static const border = Color(0xFF2B2E35);

  /// oklch(24% 0.008 260) — card borders, dividers
  static const borderLight = Color(0xFF353942);

  /// oklch(68% 0.16 85) — prestige gold (matches [VColors.brand])
  static const accent = Color(0xFFC9A227);

  /// ~14% accent tint — active pills, selected rails
  static const accentSoft = Color(0x24C9A227);
}
