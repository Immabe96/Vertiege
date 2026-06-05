import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../theme/v_colors.dart';
import '../../theme/v_fonts.dart';

/// Spike-only bridge: Vertiege tokens → [ShadThemeData].
abstract final class VertiegeShadTheme {
  static ShadThemeData light = _build(isDark: false);
  static ShadThemeData dark = _build(isDark: true);

  static ShadThemeData forBrightness(Brightness brightness) {
    return brightness == Brightness.dark ? dark : light;
  }

  static ShadThemeData _build({required bool isDark}) {
    final scheme = isDark ? _darkScheme : _lightScheme;
    return ShadThemeData(
      brightness: isDark ? Brightness.dark : Brightness.light,
      colorScheme: scheme,
      textTheme: ShadTextTheme(family: VFonts.sansFamily),
    );
  }

  static final _lightScheme = ShadZincColorScheme.light(
    background: VColors.surface,
    foreground: VColors.onSurface,
    card: VColors.surfaceContainerLowest,
    cardForeground: VColors.onSurface,
    primary: VColors.primary,
    primaryForeground: VColors.onPrimary,
    secondary: VColors.surfaceContainerLow,
    secondaryForeground: VColors.onSurface,
    muted: VColors.surfaceContainer,
    mutedForeground: VColors.onSurfaceVariant,
    accent: VColors.brandContainer,
    accentForeground: VColors.onBrandContainer,
    destructive: VColors.error,
    destructiveForeground: VColors.onError,
    border: VColors.outlineVariant,
    input: VColors.outlineVariant,
    ring: VColors.primary,
  );

  static final _darkScheme = ShadZincColorScheme.dark(
    background: VColors.surfaceDark,
    foreground: VColors.onSurfaceDark,
    card: VColors.surfaceContainerDark,
    cardForeground: VColors.onSurfaceDark,
    primary: VColors.primaryLight,
    primaryForeground: VColors.primaryDark,
    secondary: VColors.surfaceContainerHighDark,
    secondaryForeground: VColors.onSurfaceDark,
    muted: VColors.surfaceContainerDark,
    mutedForeground: VColors.onSurfaceVariantDark,
    accent: VColors.brandContainerDark,
    accentForeground: VColors.onBrandContainerDark,
    destructive: VColors.error,
    destructiveForeground: VColors.onError,
    border: VColors.outlineVariantDark,
    input: VColors.outlineVariantDark,
    ring: VColors.primaryLight,
  );
}
