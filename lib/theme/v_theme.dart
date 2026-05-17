import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'v_colors.dart';
import 'v_tokens.dart';

class VTheme {
  VTheme._();

  static ThemeData get light => _build(false);
  static ThemeData get dark => _build(true);

  static ThemeData _build(bool isDark) {
    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: VColors.primary,
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: isDark ? VColors.primaryLight : VColors.primary,
        onPrimary: VColors.onPrimary,
        primaryContainer: isDark ? VColors.primaryContainerDark : VColors.primaryContainer,
        onPrimaryContainer: isDark ? VColors.onPrimaryContainerDark : VColors.onPrimaryContainer,
        secondary: isDark ? VColors.secondaryLight : VColors.secondary,
        onSecondary: VColors.onSecondary,
        secondaryContainer: isDark ? VColors.secondaryContainerDark : VColors.secondaryContainer,
        onSecondaryContainer: isDark ? VColors.onSecondaryContainerDark : VColors.onSecondaryContainer,
        tertiary: isDark ? VColors.tertiaryLight : VColors.tertiary,
        onTertiary: VColors.onTertiary,
        tertiaryContainer: isDark ? VColors.tertiaryContainerDark : VColors.tertiaryContainer,
        onTertiaryContainer: isDark ? VColors.onTertiaryContainerDark : VColors.onTertiaryContainer,
        error: VColors.error,
        errorContainer: isDark ? VColors.errorContainerDark : VColors.errorContainer,
        onError: VColors.onError,
        onErrorContainer: isDark ? VColors.onErrorContainerDark : VColors.onErrorContainer,
        surface: isDark ? VColors.surfaceDark : VColors.surface,
        onSurface: isDark ? VColors.onSurfaceDark : VColors.onSurface,
        surfaceContainerLowest: isDark ? VColors.surfaceContainerLowestDark : VColors.surfaceContainerLowest,
        surfaceContainerLow: isDark ? VColors.surfaceContainerLowDark : VColors.surfaceContainerLow,
        surfaceContainer: isDark ? VColors.surfaceContainerDark : VColors.surfaceContainer,
        surfaceContainerHigh: isDark ? VColors.surfaceContainerHighDark : VColors.surfaceContainerHigh,
        surfaceContainerHighest: isDark ? VColors.surfaceContainerHighestDark : VColors.surfaceContainerHighest,
        onSurfaceVariant: isDark ? VColors.onSurfaceVariantDark : VColors.onSurfaceVariant,
        outline: isDark ? VColors.outlineDark : VColors.outline,
        outlineVariant: isDark ? VColors.outlineVariantDark : VColors.outlineVariant,
        inverseSurface: isDark ? VColors.inverseSurfaceLight : VColors.inverseSurface,
        onInverseSurface: isDark ? VColors.onInverseSurfaceDark : VColors.onInverseSurface,
        inversePrimary: isDark ? VColors.inversePrimaryDark : VColors.inversePrimary,
      ),
      textTheme: _textTheme(isDark),
      appBarTheme: _appBarTheme(isDark),
      navigationBarTheme: _navBarTheme(isDark),
      cardTheme: _cardTheme(isDark),
      inputDecorationTheme: _inputTheme(isDark),
      elevatedButtonTheme: _elevatedButtonTheme(isDark),
      filledButtonTheme: _filledButtonTheme(isDark),
      outlinedButtonTheme: _outlinedButtonTheme(isDark),
      textButtonTheme: _textButtonTheme(isDark),
      chipTheme: _chipTheme(isDark),
      floatingActionButtonTheme: _fabTheme(isDark),
      snackBarTheme: _snackBarTheme(isDark),
      dialogTheme: _dialogTheme(isDark),
      dividerTheme: _dividerTheme(isDark),
      tabBarTheme: _tabBarTheme(isDark),
      listTileTheme: _listTileTheme(isDark),
      switchTheme: _switchTheme(isDark),
      bottomSheetTheme: _bottomSheetTheme(isDark),
      scaffoldBackgroundColor: isDark ? VColors.surfaceDark : VColors.surface,
    );
  }

  static TextTheme _textTheme(bool isDark) {
    final base = GoogleFonts.plusJakartaSans(
      color: isDark ? VColors.onSurfaceDark : VColors.onSurface,
    );
    return TextTheme(
      displayLarge: base.copyWith(fontSize: VFontSize.displayXl, fontWeight: VFontWeight.bold, height: VLineHeight.display),
      displayMedium: base.copyWith(fontSize: VFontSize.displayLg, fontWeight: VFontWeight.bold, height: VLineHeight.display),
      headlineLarge: base.copyWith(fontSize: VFontSize.headlineLg, fontWeight: VFontWeight.bold, height: VLineHeight.headline),
      headlineMedium: base.copyWith(fontSize: VFontSize.headlineMd, fontWeight: VFontWeight.semiBold, height: VLineHeight.headline),
      headlineSmall: base.copyWith(fontSize: VFontSize.headlineSm, fontWeight: VFontWeight.semiBold, height: VLineHeight.headline),
      titleLarge: base.copyWith(fontSize: VFontSize.bodyLg, fontWeight: VFontWeight.semiBold, height: VLineHeight.body),
      titleMedium: base.copyWith(fontSize: VFontSize.bodyMd, fontWeight: VFontWeight.medium, height: VLineHeight.body),
      bodyLarge: base.copyWith(fontSize: VFontSize.bodyLg, fontWeight: VFontWeight.regular, height: VLineHeight.bodyLg),
      bodyMedium: base.copyWith(fontSize: VFontSize.bodyMd, fontWeight: VFontWeight.regular, height: VLineHeight.body),
      bodySmall: base.copyWith(fontSize: VFontSize.bodySm, fontWeight: VFontWeight.regular, height: VLineHeight.body),
      labelLarge: base.copyWith(fontSize: VFontSize.labelLg, fontWeight: VFontWeight.medium, height: VLineHeight.label),
      labelMedium: base.copyWith(fontSize: VFontSize.labelMd, fontWeight: VFontWeight.medium, height: VLineHeight.label),
      labelSmall: base.copyWith(fontSize: VFontSize.labelSm, fontWeight: VFontWeight.medium, height: VLineHeight.label),
    );
  }

  static AppBarTheme _appBarTheme(bool isDark) => AppBarTheme(
    backgroundColor: isDark ? VColors.surfaceDark.withValues(alpha: 0.8) : VColors.surface.withValues(alpha: 0.8),
    elevation: 0,
    centerTitle: false,
    titleTextStyle: GoogleFonts.plusJakartaSans(fontSize: VFontSize.headlineMd, fontWeight: VFontWeight.semiBold, color: isDark ? VColors.onSurfaceDark : VColors.onSurface),
    iconTheme: IconThemeData(color: isDark ? VColors.onSurfaceDark : VColors.onSurface, size: VIconSize.lg),
  );

  static NavigationBarThemeData _navBarTheme(bool isDark) => NavigationBarThemeData(
    backgroundColor: isDark ? VColors.surfaceContainerDark : VColors.surfaceContainer,
    indicatorColor: isDark ? VColors.primaryContainerDark.withValues(alpha: 0.3) : VColors.primaryContainer.withValues(alpha: 0.3),
    labelTextStyle: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return GoogleFonts.plusJakartaSans(fontSize: VFontSize.labelMd, fontWeight: VFontWeight.medium, color: isDark ? VColors.onSurfaceDark : VColors.onSurface);
      }
      return GoogleFonts.plusJakartaSans(fontSize: VFontSize.labelMd, fontWeight: VFontWeight.regular, color: isDark ? VColors.onSurfaceVariantDark : VColors.onSurfaceVariant);
    }),
    iconTheme: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return IconThemeData(color: isDark ? VColors.primaryLight : VColors.primary, size: VIconSize.lg);
      }
      return IconThemeData(color: isDark ? VColors.onSurfaceVariantDark : VColors.onSurfaceVariant, size: VIconSize.lg);
    }),
  );

  static CardThemeData _cardTheme(bool isDark) => CardThemeData(
    color: isDark ? VColors.surfaceContainerDark : VColors.surfaceContainerLow,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(VRadius.lg),
      side: BorderSide(color: isDark ? VColors.outlineVariantDark.withValues(alpha: 0.2) : VColors.outlineVariant.withValues(alpha: 0.3)),
    ),
    margin: EdgeInsets.zero,
  );

  static InputDecorationTheme _inputTheme(bool isDark) => InputDecorationTheme(
    filled: true,
    fillColor: isDark ? VColors.surfaceContainerDark : VColors.surfaceContainerLow,
    contentPadding: const EdgeInsets.symmetric(horizontal: VSpacing.lg, vertical: VSpacing.md),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(VRadius.md), borderSide: BorderSide(color: isDark ? VColors.outlineDark : VColors.outline)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(VRadius.md), borderSide: BorderSide(color: isDark ? VColors.outlineVariantDark : VColors.outlineVariant)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(VRadius.md), borderSide: const BorderSide(color: VColors.primary, width: 2)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(VRadius.md), borderSide: const BorderSide(color: VColors.error)),
    focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(VRadius.md), borderSide: const BorderSide(color: VColors.error, width: 2)),
    hintStyle: GoogleFonts.plusJakartaSans(fontSize: VFontSize.bodyMd, color: isDark ? VColors.onSurfaceVariantDark.withValues(alpha: 0.6) : VColors.onSurfaceVariant.withValues(alpha: 0.6)),
  );

  static ElevatedButtonThemeData _elevatedButtonTheme(bool isDark) => ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: isDark ? VColors.primaryLight : VColors.primary,
      foregroundColor: VColors.onPrimary,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: VSpacing.xl, vertical: VSpacing.md),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VRadius.md)),
      textStyle: GoogleFonts.plusJakartaSans(fontSize: VFontSize.labelLg, fontWeight: VFontWeight.semiBold),
    ),
  );

  static FilledButtonThemeData _filledButtonTheme(bool isDark) => FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: isDark ? VColors.primaryLight : VColors.primary,
      foregroundColor: VColors.onPrimary,
      padding: const EdgeInsets.symmetric(horizontal: VSpacing.xl, vertical: VSpacing.md),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VRadius.md)),
      textStyle: GoogleFonts.plusJakartaSans(fontSize: VFontSize.labelLg, fontWeight: VFontWeight.semiBold),
    ),
  );

  static OutlinedButtonThemeData _outlinedButtonTheme(bool isDark) => OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: isDark ? VColors.primaryLight : VColors.primary,
      side: BorderSide(color: isDark ? VColors.primaryLight.withValues(alpha: 0.3) : VColors.primary.withValues(alpha: 0.3)),
      padding: const EdgeInsets.symmetric(horizontal: VSpacing.xl, vertical: VSpacing.md),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VRadius.md)),
      textStyle: GoogleFonts.plusJakartaSans(fontSize: VFontSize.labelLg, fontWeight: VFontWeight.semiBold),
    ),
  );

  static TextButtonThemeData _textButtonTheme(bool isDark) => TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: isDark ? VColors.primaryLight : VColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: VSpacing.md, vertical: VSpacing.sm),
      textStyle: GoogleFonts.plusJakartaSans(fontSize: VFontSize.labelLg, fontWeight: VFontWeight.medium),
    ),
  );

  static ChipThemeData _chipTheme(bool isDark) => ChipThemeData(
    backgroundColor: isDark ? VColors.surfaceContainerHighDark : VColors.surfaceContainerHigh,
    selectedColor: isDark ? VColors.primaryContainerDark : VColors.primaryContainer,
    labelStyle: GoogleFonts.plusJakartaSans(fontSize: VFontSize.labelMd, fontWeight: VFontWeight.medium, color: isDark ? VColors.onSurfaceDark : VColors.onSurface),
    padding: const EdgeInsets.symmetric(horizontal: VSpacing.md, vertical: VSpacing.xs),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VRadius.pill)),
  );

  static FloatingActionButtonThemeData _fabTheme(bool isDark) => FloatingActionButtonThemeData(
    backgroundColor: isDark ? VColors.primaryLight : VColors.primary,
    foregroundColor: VColors.onPrimary,
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VRadius.lg)),
  );

  static SnackBarThemeData _snackBarTheme(bool isDark) => SnackBarThemeData(
    backgroundColor: isDark ? VColors.surfaceContainerHighDark : VColors.inverseSurface,
    contentTextStyle: GoogleFonts.plusJakartaSans(fontSize: VFontSize.bodyMd, color: isDark ? VColors.onSurfaceDark : VColors.onInverseSurface),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VRadius.md)),
    behavior: SnackBarBehavior.floating,
  );

  static DialogThemeData _dialogTheme(bool isDark) => DialogThemeData(
    backgroundColor: isDark ? VColors.surfaceContainerDark : VColors.surfaceContainerLow,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VRadius.xl)),
    titleTextStyle: GoogleFonts.plusJakartaSans(fontSize: VFontSize.headlineMd, fontWeight: VFontWeight.semiBold, color: isDark ? VColors.onSurfaceDark : VColors.onSurface),
    contentTextStyle: GoogleFonts.plusJakartaSans(fontSize: VFontSize.bodyMd, color: isDark ? VColors.onSurfaceVariantDark : VColors.onSurfaceVariant),
  );

  static DividerThemeData _dividerTheme(bool isDark) => DividerThemeData(
    color: isDark ? VColors.outlineVariantDark : VColors.outlineVariant,
    thickness: 1,
    space: 1,
  );

  static TabBarThemeData _tabBarTheme(bool isDark) => TabBarThemeData(
    labelColor: isDark ? VColors.primaryLight : VColors.primary,
    unselectedLabelColor: isDark ? VColors.onSurfaceVariantDark : VColors.onSurfaceVariant,
    labelStyle: GoogleFonts.plusJakartaSans(fontSize: VFontSize.labelLg, fontWeight: VFontWeight.semiBold),
    unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: VFontSize.labelLg, fontWeight: VFontWeight.regular),
    indicator: const UnderlineTabIndicator(borderSide: BorderSide(color: VColors.primary, width: 2)),
  );

  static ListTileThemeData _listTileTheme(bool isDark) => ListTileThemeData(
    contentPadding: const EdgeInsets.symmetric(horizontal: VSpacing.lg, vertical: VSpacing.xs),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VRadius.md)),
    titleTextStyle: GoogleFonts.plusJakartaSans(fontSize: VFontSize.bodyMd, fontWeight: VFontWeight.medium, color: isDark ? VColors.onSurfaceDark : VColors.onSurface),
    subtitleTextStyle: GoogleFonts.plusJakartaSans(fontSize: VFontSize.bodySm, color: isDark ? VColors.onSurfaceVariantDark : VColors.onSurfaceVariant),
  );

  static SwitchThemeData _switchTheme(bool isDark) => SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return isDark ? VColors.primaryLight : VColors.primary;
      return isDark ? VColors.onSurfaceVariantDark : VColors.onSurfaceVariant;
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return isDark ? VColors.primaryContainerDark : VColors.primaryContainer;
      return isDark ? VColors.surfaceContainerHighDark : VColors.surfaceContainerHigh;
    }),
  );

  static BottomSheetThemeData _bottomSheetTheme(bool isDark) => BottomSheetThemeData(
    backgroundColor: isDark ? VColors.surfaceContainerDark : VColors.surfaceContainerLow,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(VRadius.xl))),
    modalBackgroundColor: isDark ? VColors.surfaceContainerDark : VColors.surfaceContainerLow,
  );
}
