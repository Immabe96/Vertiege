import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';
import 'design_system.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get theme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
      surface: AppColors.canvas,
    ).copyWith(
      surface: AppColors.canvas,
      surfaceContainer: AppColors.surface,
      surfaceContainerHighest: AppColors.surfaceElevated,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      onSurface: AppColors.ink,
      onSurfaceVariant: AppColors.inkSecondary,
      outline: AppColors.borderDefault,
      outlineVariant: AppColors.borderSubtle,
      error: AppColors.error,
      tertiary: AppColors.tertiary,
      onTertiary: AppColors.onTertiary,
      shadow: Colors.transparent,
    );

    final interTextTheme = GoogleFonts.interTextTheme(
      ThemeData.dark().textTheme.apply(
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
        decorationColor: AppColors.inkSecondary,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.canvas,
      textTheme: interTextTheme.copyWith(
        displayLarge: interTextTheme.displayLarge?.copyWith(
          fontSize: FontSizes.displayXl,
          fontWeight: FontWeights.bold,
          letterSpacing: LetterSpacing.display,
          height: LineHeight.display,
        ),
        headlineLarge: interTextTheme.headlineLarge?.copyWith(
          fontSize: FontSizes.headlineLg,
          fontWeight: FontWeights.semiBold,
          letterSpacing: LetterSpacing.headline,
          height: LineHeight.headlineLg,
        ),
        headlineMedium: interTextTheme.headlineMedium?.copyWith(
          fontSize: FontSizes.headlineMd,
          fontWeight: FontWeights.semiBold,
          height: LineHeight.headline,
        ),
        bodyLarge: interTextTheme.bodyLarge?.copyWith(
          fontSize: FontSizes.bodyLg,
          fontWeight: FontWeights.regular,
          height: LineHeight.bodyLg,
        ),
        bodyMedium: interTextTheme.bodyMedium?.copyWith(
          fontSize: FontSizes.bodyMd,
          fontWeight: FontWeights.regular,
          height: LineHeight.body,
        ),
        labelSmall: interTextTheme.labelSmall?.copyWith(
          fontSize: FontSizes.labelSm,
          fontWeight: FontWeights.semiBold,
          letterSpacing: LetterSpacing.label,
          height: LineHeight.label,
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: AppColors.surface.withValues(alpha: 0.8),
        titleTextStyle: GoogleFonts.spaceGrotesk(
          fontSize: FontSizes.headlineLg,
          fontWeight: FontWeights.bold,
          color: AppColors.tertiary,
          letterSpacing: -0.5,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        backgroundColor: Colors.transparent,
        selectedItemColor: AppColors.tertiary,
        unselectedItemColor: AppColors.inkMuted,
        selectedLabelStyle: TextStyle(
          fontSize: FontSizes.labelSm,
          fontWeight: FontWeights.semiBold,
          letterSpacing: LetterSpacing.label,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: FontSizes.labelSm,
          fontWeight: FontWeights.regular,
          letterSpacing: LetterSpacing.label,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.glassBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.xl),
          side: const BorderSide(color: AppColors.glassBorder),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.xs,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        border: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.outlineVariant),
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.outlineVariant),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.tertiary),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 0,
          vertical: Spacing.sm + 4,
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: FontSizes.labelSm,
          fontWeight: FontWeights.semiBold,
          color: AppColors.tertiary,
          letterSpacing: LetterSpacing.label,
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: FontSizes.bodyMd,
          color: AppColors.inkMuted,
        ),
        isDense: false,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.tertiary,
          foregroundColor: AppColors.onTertiary,
          textStyle: GoogleFonts.inter(
            fontSize: FontSizes.labelSm,
            fontWeight: FontWeights.semiBold,
            letterSpacing: LetterSpacing.label,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RadiusTokens.md),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.xl,
            vertical: Spacing.md,
          ),
          minimumSize: const Size(0, TouchTargets.minimum),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.inter(
            fontSize: FontSizes.labelSm,
            fontWeight: FontWeights.semiBold,
            letterSpacing: LetterSpacing.label,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RadiusTokens.md),
          ),
          side: const BorderSide(color: AppColors.glassBorder),
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.xl,
            vertical: Spacing.md,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceElevated,
        selectedColor: AppColors.primary.withValues(alpha: AppColors.alphaSelected),
        labelStyle: GoogleFonts.inter(
          fontSize: FontSizes.labelSm,
          fontWeight: FontWeights.regular,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.lg),
          side: const BorderSide(color: AppColors.glassBorder),
        ),
        side: const BorderSide(color: AppColors.glassBorder),
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.xs,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 0,
        backgroundColor: AppColors.hustler,
        foregroundColor: Colors.black,
        shape: CircleBorder(),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.xl),
        ),
        backgroundColor: AppColors.surfaceHigh,
        contentTextStyle: GoogleFonts.inter(
          fontSize: FontSizes.bodyMd,
          color: AppColors.ink,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.glassModalBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.full),
        ),
      ),
      dividerTheme: const DividerThemeData(
        space: 1,
        thickness: 0.5,
        color: AppColors.borderSubtle,
      ),
      tabBarTheme: TabBarThemeData(
        indicatorSize: TabBarIndicatorSize.tab,
        dividerHeight: 0,
        labelColor: AppColors.tertiary,
        unselectedLabelColor: AppColors.inkSecondary,
        labelStyle: GoogleFonts.inter(
          fontSize: FontSizes.labelSm,
          fontWeight: FontWeights.semiBold,
          letterSpacing: LetterSpacing.label,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: FontSizes.labelSm,
          fontWeight: FontWeights.regular,
        ),
      ),
    );
  }
}
