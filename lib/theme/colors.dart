import 'package:flutter/material.dart';

/// Design tokens sourced from Open Design:
///   Discord — status colors, surface hierarchy, blurple accent
///   Duolingo — gamification colors, tactile button greens, streak orange
///   Supabase — green accent, clean surface palette
class AppColors {
  AppColors._();

  // ── Primary ──────────────────────────────────────────
  static const Color seed = Color(0xFF5865F2); // Discord blurple

  // ── Status (Discord) ─────────────────────────────────
  static const Color online = Color(0xFF23A55A);
  static const Color idle = Color(0xFFF0B232);
  static const Color dnd = Color(0xFFF23F43);
  static const Color offline = Color(0xFF80848E);
  static const Color streaming = Color(0xFF593695);

  // ── Gamification (Duolingo) ──────────────────────────
  static const Color owlGreen = Color(0xFF58CC02);
  static const Color owlGreenDeep = Color(0xFF58A700);
  static const Color streakOrange = Color(0xFFFF9600);
  static const Color streakOrangeDeep = Color(0xFFCC7A00);
  static const Color gemPink = Color(0xFFCE82FF);
  static const Color beeYellow = Color(0xFFFFC800);
  static const Color eelBlue = Color(0xFF1CB0F6);

  // ── Brand ────────────────────────────────────────────
  static const Color brandGreen = Color(0xFF3ECF8E);

  // ── Semantic ─────────────────────────────────────────
  static const Color emerald = Color(0xFF2D8B57);
  static const Color crimson = Color(0xFF8B2252);
  static const Color dangerRed = Color(0xFFDA373C);

  // ── Medal ────────────────────────────────────────────
  static const Color gold = Color(0xFFD4A843);
  static const Color silver = Color(0xFFC0C0C0);
  static const Color bronze = Color(0xFFCD7F32);

  // ── Surface hierarchy tokens ─────────────────────────
  static const Color darkSurfaceBase = Color(0xFF1A1B1E);
  static const Color darkSurfaceRaised = Color(0xFF1E1F22);
  static const Color darkSurfaceCard = Color(0xFF2B2D31);
  static const Color darkSurfaceOverlay = Color(0xFF313338);
  static const Color darkSurfaceHighest = Color(0xFF383A40);

  // ── Gradient stops ───────────────────────────────────
  static const List<Color> gradientPrimary = [
    Color(0xFF5865F2),
    Color(0xFF7C6FFD),
  ];
  static const List<Color> gradientBrand = [
    Color(0xFF5865F2),
    Color(0xFF3ECF8E),
  ];
  static const List<Color> gradientWarm = [
    Color(0xFFFF9600),
    Color(0xFFFF5764),
  ];
  static const List<Color> gradientDark = [
    Color(0xFF1A1B1E),
    Color(0xFF2B2D31),
  ];

  // ── Opacity presets ──────────────────────────────────
  static const double alphaHover = 0.06;
  static const double alphaPressed = 0.12;
  static const double alphaSelected = 0.15;
  static const double alphaBorder = 0.15;
  static const double alphaDisabled = 0.38;
  static const double alphaOverlay = 0.60;
}
