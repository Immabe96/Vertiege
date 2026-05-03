import 'package:flutter/material.dart';
import 'colors.dart';
import 'design_system.dart';

class AppTheme {
  AppTheme._();

  static const _cardRadius = 12.0;
  static const _inputRadius = 8.0;
  static const _buttonRadius = 8.0;
  static const _pillRadius = 9999.0;

  // ── Light ──────────────────────────────────────────────────────────────
  static final ThemeData light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: Colors.grey.shade50,
    // ── AppBar ──
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 1,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        fontSize: FontSizes.title,
        fontWeight: FontWeight.w600,
        letterSpacing: LetterSpacing.heading,
        color: Colors.black,
      ),
    ),
    // ── Bottom Nav ──
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      elevation: 0,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(
        fontSize: FontSizes.caption,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: FontSizes.caption,
      ),
    ),
    // ── Cards ──
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_cardRadius),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    ),
    // ── Inputs ──
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(_inputRadius)),
      filled: true,
      fillColor: Colors.grey.shade100,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      isDense: true,
    ),
    // ── Buttons ──
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
    // ── Tabs ──
    tabBarTheme: TabBarThemeData(
      indicatorSize: TabBarIndicatorSize.tab,
      dividerHeight: 0,
    ),
    // ── Chips ──
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_pillRadius)),
    ),
    // ── SnackBar ──
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(RadiusTokens.md)),
      contentTextStyle: const TextStyle(fontSize: FontSizes.body),
    ),
    // ── Dialog ──
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(RadiusTokens.lg)),
      titleTextStyle: const TextStyle(
        fontSize: FontSizes.subhead,
        fontWeight: FontWeight.w600,
        letterSpacing: LetterSpacing.tight,
      ),
    ),
    // ── FAB ──
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_buttonRadius)),
    ),
    // ── Divider ──
    dividerTheme: DividerThemeData(
      space: 1,
      thickness: BorderWidth.thin,
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
    scaffoldBackgroundColor: AppColors.darkSurfaceBase,
    // ── AppBar ──
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 1,
      surfaceTintColor: Colors.transparent,
      backgroundColor: AppColors.darkSurfaceBase,
      titleTextStyle: const TextStyle(
        fontSize: FontSizes.title,
        fontWeight: FontWeight.w600,
        letterSpacing: LetterSpacing.heading,
        color: Colors.white,
      ),
    ),
    // ── Bottom Nav ──
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      elevation: 0,
      backgroundColor: AppColors.darkSurfaceRaised,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: const TextStyle(
        fontSize: FontSizes.caption,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: FontSizes.caption,
      ),
    ),
    // ── Cards ──
    cardTheme: CardThemeData(
      elevation: 0,
      color: AppColors.darkSurfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_cardRadius),
        side: const BorderSide(color: Color(0xFF3F4147)),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    ),
    // ── Inputs ──
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(_inputRadius)),
      filled: true,
      fillColor: AppColors.darkSurfaceBase,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      isDense: true,
    ),
    // ── Buttons ──
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
    // ── Tabs ──
    tabBarTheme: TabBarThemeData(
      indicatorSize: TabBarIndicatorSize.tab,
      dividerHeight: 0,
    ),
    // ── Chips ──
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_pillRadius)),
    ),
    // ── SnackBar ──
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(RadiusTokens.md)),
    ),
    // ── Dialog ──
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(RadiusTokens.lg)),
      titleTextStyle: const TextStyle(
        fontSize: FontSizes.subhead,
        fontWeight: FontWeight.w600,
        letterSpacing: LetterSpacing.tight,
      ),
    ),
    // ── FAB ──
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_buttonRadius)),
    ),
    // ── Divider ──
    dividerTheme: const DividerThemeData(
      space: 1,
      thickness: BorderWidth.thin,
    ),
  );
}
