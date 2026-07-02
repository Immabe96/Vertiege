import 'package:flutter/material.dart';
import 'v_colors.dart';
import 'v_fonts.dart';
import 'v_tokens.dart';
import 'prestige_noir.dart';

class VTheme {
  VTheme._();

  /// Prestige Noir — sole app theme.
  static ThemeData get dark => _build();

  /// Legacy aliases — never use light in production.
  static ThemeData get light => dark;
  static ThemeData get lightCommune => dark;
  static ThemeData get darkCommune => dark;

  static ThemeData _build() {
        return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: VColors.brand,
        brightness: Brightness.dark,
        primary: VColors.primaryLight,
        onPrimary: VColors.onPrimary,
        primaryContainer: VColors.primaryContainerDark,
        onPrimaryContainer: VColors.onPrimaryContainerDark,
        secondary: VColors.secondaryLight,
        onSecondary: VColors.onSecondary,
        secondaryContainer: VColors.secondaryContainerDark,
        onSecondaryContainer: VColors.onSecondaryContainerDark,
        tertiary: VColors.tertiaryLight,
        onTertiary: VColors.onTertiary,
        tertiaryContainer: VColors.tertiaryContainerDark,
        onTertiaryContainer: VColors.onTertiaryContainerDark,
        error: VColors.error,
        errorContainer: VColors.errorContainerDark,
        onError: VColors.onError,
        onErrorContainer: VColors.onErrorContainerDark,
        surface: VColors.surfaceDark,
        onSurface: VColors.onSurfaceDark,
        surfaceContainerLowest: VColors.surfaceContainerLowestDark,
        surfaceContainerLow: VColors.surfaceContainerLowDark,
        surfaceContainer: VColors.surfaceContainerDark,
        surfaceContainerHigh: VColors.surfaceContainerHighDark,
        surfaceContainerHighest: VColors.surfaceContainerHighestDark,
        onSurfaceVariant: VColors.onSurfaceVariantDark,
        outline: VColors.outlineDark,
        outlineVariant: VColors.outlineVariantDark,
        inverseSurface: VColors.inverseSurfaceLight,
        onInverseSurface: VColors.onInverseSurfaceDark,
        inversePrimary: VColors.inversePrimaryDark,
      ),
      textTheme: VFonts.apply(_textTheme()),
      appBarTheme: _appBarTheme(),
      navigationBarTheme: _navBarTheme(),
      cardTheme: _cardTheme(),
      inputDecorationTheme: _inputTheme(),
      elevatedButtonTheme: _elevatedButtonTheme(),
      filledButtonTheme: _filledButtonTheme(),
      outlinedButtonTheme: _outlinedButtonTheme(),
      textButtonTheme: _textButtonTheme(),
      chipTheme: _chipTheme(),
      floatingActionButtonTheme: _fabTheme(),
      snackBarTheme: _snackBarTheme(),
      dialogTheme: _dialogTheme(),
      dividerTheme: _dividerTheme(),
      tabBarTheme: _tabBarTheme(),
      listTileTheme: _listTileTheme(),
      switchTheme: _switchTheme(),
      bottomSheetTheme: _bottomSheetTheme(),
      scaffoldBackgroundColor: VColors.surfaceDark,
    );
  }

  static TextStyle _font({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    FontStyle? fontStyle,
  }) =>
      VFonts.sans(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        fontStyle: fontStyle,
      );

  static TextTheme _textTheme() {
    final base = _font(
      color: VColors.onSurfaceDark,
    );
    return TextTheme(
      displayLarge: base.copyWith(
        fontSize: VFontSize.displayXl,
        fontWeight: VFontWeight.bold,
        height: VLineHeight.display,
      ),
      displayMedium: base.copyWith(
        fontSize: VFontSize.displayLg,
        fontWeight: VFontWeight.bold,
        height: VLineHeight.display,
      ),
      headlineLarge: base.copyWith(
        fontSize: VFontSize.headlineLg,
        fontWeight: VFontWeight.bold,
        height: VLineHeight.headline,
      ),
      headlineMedium: base.copyWith(
        fontSize: VFontSize.headlineMd,
        fontWeight: VFontWeight.semiBold,
        height: VLineHeight.headline,
      ),
      headlineSmall: base.copyWith(
        fontSize: VFontSize.headlineSm,
        fontWeight: VFontWeight.semiBold,
        height: VLineHeight.headline,
      ),
      titleLarge: base.copyWith(
        fontSize: VFontSize.bodyLg,
        fontWeight: VFontWeight.semiBold,
        height: VLineHeight.body,
      ),
      titleMedium: base.copyWith(
        fontSize: VFontSize.bodyMd,
        fontWeight: VFontWeight.medium,
        height: VLineHeight.body,
      ),
      bodyLarge: base.copyWith(
        fontSize: VFontSize.bodyLg,
        fontWeight: VFontWeight.regular,
        height: VLineHeight.bodyLg,
      ),
      bodyMedium: base.copyWith(
        fontSize: VFontSize.bodyMd,
        fontWeight: VFontWeight.regular,
        height: VLineHeight.body,
      ),
      bodySmall: base.copyWith(
        fontSize: VFontSize.bodySm,
        fontWeight: VFontWeight.regular,
        height: VLineHeight.body,
      ),
      labelLarge: base.copyWith(
        fontSize: VFontSize.labelLg,
        fontWeight: VFontWeight.medium,
        height: VLineHeight.label,
      ),
      labelMedium: base.copyWith(
        fontSize: VFontSize.labelMd,
        fontWeight: VFontWeight.medium,
        height: VLineHeight.label,
      ),
      labelSmall: base.copyWith(
        fontSize: VFontSize.labelSm,
        fontWeight: VFontWeight.medium,
        height: VLineHeight.label,
      ),
    );
  }

  static AppBarTheme _appBarTheme() => AppBarTheme(
    backgroundColor: VColors.surfaceDark.withValues(alpha: 0.8),
    elevation: 0,
    centerTitle: false,
    titleTextStyle: _font(
      fontSize: VFontSize.headlineMd,
      fontWeight: VFontWeight.semiBold,
      color: VColors.onSurfaceDark,
    ),
    iconTheme: const IconThemeData(
      color: VColors.onSurfaceDark,
      size: VIconSize.lg,
    ),
  );

  static NavigationBarThemeData _navBarTheme() => NavigationBarThemeData(
    backgroundColor: PrestigeNoir.chrome,
    indicatorColor: VColors.brandSoft(Brightness.dark),
    labelTextStyle: WidgetStateProperty.resolveWith((states) {
      final selected = states.contains(WidgetState.selected);
      return _font(
        fontSize: VFontSize.labelMd,
        fontWeight: selected ? VFontWeight.semiBold : VFontWeight.regular,
        color: selected ? VColors.brand : VColors.onSurfaceVariantDark,
      );
    }),
    iconTheme: WidgetStateProperty.resolveWith((states) {
      final selected = states.contains(WidgetState.selected);
      return IconThemeData(
        color: selected ? VColors.brand : VColors.onSurfaceVariantDark,
        size: VIconSize.lg,
      );
    }),
  );

  static CardThemeData _cardTheme() => CardThemeData(
    color: VColors.surfaceContainerDark,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(VRadius.lg),
      side: BorderSide(
        color: VColors.outlineVariantDark.withValues(alpha: 0.2),
      ),
    ),
    margin: EdgeInsets.zero,
  );

  static InputDecorationTheme _inputTheme() => InputDecorationTheme(
    filled: true,
    fillColor: VColors.surfaceContainerDark,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: VSpacing.lg,
      vertical: VSpacing.md,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(VRadius.md),
      borderSide: const BorderSide(
        color: VColors.outlineDark,
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(VRadius.md),
      borderSide: const BorderSide(
        color: VColors.outlineVariantDark,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(VRadius.md),
      borderSide: const BorderSide(
        color: VColors.primaryLight,
        width: 2,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(VRadius.md),
      borderSide: const BorderSide(color: VColors.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(VRadius.md),
      borderSide: const BorderSide(color: VColors.error, width: 2),
    ),
    hintStyle: _font(
      fontSize: VFontSize.bodyMd,
      color: VColors.onSurfaceVariantDark.withValues(alpha: 0.6),
    ),
  );

  static ElevatedButtonThemeData _elevatedButtonTheme() =>
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: VColors.primaryLight,
          foregroundColor: VColors.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: VSpacing.xl,
            vertical: VSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(VRadius.md),
          ),
          textStyle: _font(
            fontSize: VFontSize.labelLg,
            fontWeight: VFontWeight.semiBold,
          ),
        ),
      );

  static FilledButtonThemeData _filledButtonTheme() =>
      FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: VColors.primaryLight,
          foregroundColor: VColors.onPrimary,
          padding: const EdgeInsets.symmetric(
            horizontal: VSpacing.xl,
            vertical: VSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(VRadius.md),
          ),
          textStyle: _font(
            fontSize: VFontSize.labelLg,
            fontWeight: VFontWeight.semiBold,
          ),
        ),
      );

  static OutlinedButtonThemeData _outlinedButtonTheme() =>
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: VColors.primaryLight,
          side: BorderSide(
            color: VColors.primaryLight.withValues(alpha: 0.3),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: VSpacing.xl,
            vertical: VSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(VRadius.md),
          ),
          textStyle: _font(
            fontSize: VFontSize.labelLg,
            fontWeight: VFontWeight.semiBold,
          ),
        ),
      );

  static TextButtonThemeData _textButtonTheme() =>
      TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: VColors.primaryLight,
          padding: const EdgeInsets.symmetric(
            horizontal: VSpacing.md,
            vertical: VSpacing.sm,
          ),
          textStyle: _font(
            fontSize: VFontSize.labelLg,
            fontWeight: VFontWeight.medium,
          ),
        ),
      );

  static ChipThemeData _chipTheme() => ChipThemeData(
    backgroundColor: VColors.surfaceContainerHighDark,
    selectedColor: VColors.primaryContainerDark,
    labelStyle: _font(
      fontSize: VFontSize.labelMd,
      fontWeight: VFontWeight.medium,
      color: VColors.onSurfaceDark,
    ),
    padding: const EdgeInsets.symmetric(
      horizontal: VSpacing.md,
      vertical: VSpacing.xs,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(VRadius.pill),
    ),
  );

  static FloatingActionButtonThemeData _fabTheme() =>
      FloatingActionButtonThemeData(
        backgroundColor: VColors.brand,
        foregroundColor: VColors.onBrand,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VRadius.lg),
        ),
      );

  static SnackBarThemeData _snackBarTheme() => SnackBarThemeData(
    backgroundColor: VColors.surfaceContainerHighDark,
    contentTextStyle: _font(
      fontSize: VFontSize.bodyMd,
      color: VColors.onSurfaceDark,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(VRadius.md),
    ),
    behavior: SnackBarBehavior.floating,
  );

  static DialogThemeData _dialogTheme() => DialogThemeData(
    backgroundColor: VColors.surfaceContainerDark,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(VRadius.xl),
    ),
    titleTextStyle: _font(
      fontSize: VFontSize.headlineMd,
      fontWeight: VFontWeight.semiBold,
      color: VColors.onSurfaceDark,
    ),
    contentTextStyle: _font(
      fontSize: VFontSize.bodyMd,
      color: VColors.onSurfaceVariantDark,
    ),
  );

  static DividerThemeData _dividerTheme() => const DividerThemeData(
    color: VColors.outlineVariantDark,
    thickness: 1,
    space: 1,
  );

  static TabBarThemeData _tabBarTheme() => TabBarThemeData(
    labelColor: VColors.primaryLight,
    unselectedLabelColor: VColors.onSurfaceVariantDark,
    labelStyle: _font(
      fontSize: VFontSize.labelLg,
      fontWeight: VFontWeight.semiBold,
    ),
    unselectedLabelStyle: _font(
      fontSize: VFontSize.labelLg,
      fontWeight: VFontWeight.regular,
    ),
    indicator: const UnderlineTabIndicator(
      borderSide: BorderSide(color: VColors.primary, width: 2),
    ),
  );

  static ListTileThemeData _listTileTheme() => ListTileThemeData(
    contentPadding: const EdgeInsets.symmetric(
      horizontal: VSpacing.lg,
      vertical: VSpacing.xs,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(VRadius.md),
    ),
    titleTextStyle: _font(
      fontSize: VFontSize.bodyMd,
      fontWeight: VFontWeight.medium,
      color: VColors.onSurfaceDark,
    ),
    subtitleTextStyle: _font(
      fontSize: VFontSize.bodySm,
      color: VColors.onSurfaceVariantDark,
    ),
  );

  static SwitchThemeData _switchTheme() => SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return VColors.primaryLight;
      }
      return VColors.onSurfaceVariantDark;
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return VColors.primaryContainerDark;
      }
      return VColors.surfaceContainerHighDark;
    }),
  );

  static BottomSheetThemeData _bottomSheetTheme() =>
      const BottomSheetThemeData(
        backgroundColor: VColors.surfaceContainerDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(VRadius.xl)),
        ),
        modalBackgroundColor: VColors.surfaceContainerDark,
      );
}
