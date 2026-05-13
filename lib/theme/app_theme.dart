import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';
import 'design_system.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get theme => dark;

  static ThemeData get dark {
    final colorScheme =
        ColorScheme.fromSeed(
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
        selectedColor: AppColors.primary.withValues(
          alpha: AppColors.alphaSelected,
        ),
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

  static ThemeData get light {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: const Color(0xFF6D5BD0),
          brightness: Brightness.light,
          surface: const Color(0xFFFAFAF8),
        ).copyWith(
          primary: const Color(0xFF6D5BD0),
          onPrimary: Colors.white,
          secondary: const Color(0xFF52606D),
          tertiary: const Color(0xFFB7791F),
          onTertiary: Colors.white,
          surface: const Color(0xFFFAFAF8),
          surfaceContainer: const Color(0xFFFFFFFF),
          surfaceContainerHighest: const Color(0xFFE8E6EF),
          onSurface: const Color(0xFF1F1F23),
          onSurfaceVariant: const Color(0xFF60616A),
          outline: const Color(0xFFD8D5E0),
          outlineVariant: const Color(0xFFE8E6EF),
          error: const Color(0xFFB3261E),
          shadow: Colors.transparent,
        );

    final interTextTheme = GoogleFonts.interTextTheme(
      ThemeData.light().textTheme.apply(
        bodyColor: colorScheme.onSurface,
        displayColor: colorScheme.onSurface,
        decorationColor: colorScheme.onSurfaceVariant,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: interTextTheme,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: GoogleFonts.inter(
          fontSize: FontSizes.headlineMd,
          fontWeight: FontWeights.semiBold,
          color: colorScheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.md),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainer,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.md),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.md),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.md),
          borderSide: BorderSide(color: colorScheme.primary),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RadiusTokens.md),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.lg,
            vertical: Spacing.sm + 2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RadiusTokens.md),
          ),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainer,
        selectedColor: colorScheme.primary.withValues(alpha: 0.12),
        side: BorderSide(color: colorScheme.outlineVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.md),
        ),
      ),
      dividerTheme: DividerThemeData(
        space: 1,
        thickness: 0.5,
        color: colorScheme.outlineVariant,
      ),
    );
  }
}
