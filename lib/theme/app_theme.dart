import 'package:flutter/material.dart';
import 'colors.dart';

class AppTheme {
  AppTheme._();

  // ── Shared radius tokens (Open Design: Discord 4-8px, Supabase 6-16px) ─
  static const _cardRadius = 12.0;
  static const _inputRadius = 8.0;
  static const _buttonRadius = 8.0;
  static const _pillRadius = 9999.0;

  // ── Discord-inspired surface hierarchy (dark) ──────────────────────────
  // bg-floating > bg-primary > bg-secondary > bg-tertiary
  static const _darkSurfaceBase = Color(0xFF1E1F22);
  static const _darkSurfaceCard = Color(0xFF2B2D31);

  // ── Light ──────────────────────────────────────────────────────────────
  static final ThemeData light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: Brightness.light,
    ),
    // Cards: subtle border, no heavy shadow (Supabase pattern)
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_cardRadius),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    ),
    // Inputs: filled, compact (Discord pattern)
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(_inputRadius)),
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      isDense: true,
    ),
    // Buttons: rounded, tactile-ready (Duolingo pattern)
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_buttonRadius)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_buttonRadius)),
      ),
    ),
    // Tabs: pill-shaped (Supabase pattern)
    tabBarTheme: TabBarThemeData(
      indicatorSize: TabBarIndicatorSize.tab,
      dividerHeight: 0,
    ),
    // Chips: rounded
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_pillRadius)),
    ),
  );

  // ── Dark ───────────────────────────────────────────────────────────────
  static final ThemeData dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: Brightness.dark,
    ),
    // Cards: border-based depth, no shadows (Discord/Supabase pattern)
    cardTheme: CardThemeData(
      elevation: 0,
      color: _darkSurfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_cardRadius),
        side: const BorderSide(color: Color(0xFF3F4147)),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    ),
    // Inputs: darker surface fill
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(_inputRadius)),
      filled: true,
      fillColor: _darkSurfaceBase,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      isDense: true,
    ),
    // Buttons: tactile-ready
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_buttonRadius)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_buttonRadius)),
      ),
    ),
    tabBarTheme: TabBarThemeData(
      indicatorSize: TabBarIndicatorSize.tab,
      dividerHeight: 0,
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_pillRadius)),
    ),
  );
}
