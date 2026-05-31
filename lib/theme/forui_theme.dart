import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';

import 'v_colors.dart';
import 'v_fonts.dart';

class VertiegeForuiTheme {
  VertiegeForuiTheme._();

  static FThemeData get light => _build(isDark: false);
  static FThemeData get dark => _build(isDark: true);

  static FThemeData _build({required bool isDark}) {
    final colors = FColors(
      brightness: isDark ? Brightness.dark : Brightness.light,
      systemOverlayStyle: isDark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      barrier: isDark ? const Color(0xAA000000) : const Color(0x33000000),
      background: isDark ? VColors.surfaceDark : VColors.surface,
      foreground: isDark ? VColors.onSurfaceDark : VColors.onSurface,
      primary: isDark ? VColors.primaryLight : VColors.primary,
      primaryForeground: isDark ? VColors.primaryDark : VColors.onPrimary,
      secondary: isDark
          ? VColors.surfaceContainerHighDark
          : VColors.surfaceContainerLow,
      secondaryForeground: isDark ? VColors.onSurfaceDark : VColors.onSurface,
      muted: isDark ? VColors.surfaceContainerDark : VColors.surfaceContainer,
      mutedForeground: isDark
          ? VColors.onSurfaceVariantDark
          : VColors.onSurfaceVariant,
      destructive: VColors.error,
      destructiveForeground: VColors.onError,
      error: VColors.error,
      errorForeground: VColors.onError,
      card: isDark
          ? VColors.surfaceContainerDark
          : VColors.surfaceContainerLowest,
      border: isDark ? VColors.outlineVariantDark : VColors.outlineVariant,
    );

    return FThemeData(
      debugLabel: isDark ? 'Vertiege Prestige Noir' : 'Vertiege Light Forui',
      colors: colors,
      touch: true,
      typography:
          FTypography.inherit(
            colors: colors,
            touch: false,
            fontFamily: VFonts.sansFamily,
          ).copyWith(
            xs3: const TextStyle(fontSize: 9, height: 1),
            xs2: const TextStyle(fontSize: 11, height: 1),
            xs: const TextStyle(fontSize: 12, height: 1.15),
            sm: const TextStyle(fontSize: 14, height: 1.35),
            md: const TextStyle(fontSize: 16, height: 1.45),
            lg: const TextStyle(fontSize: 18, height: 1.35),
            xl: const TextStyle(fontSize: 20, height: 1.3),
            xl2: const TextStyle(fontSize: 24, height: 1.25),
            xl3: const TextStyle(fontSize: 28, height: 1.2),
          ),
    );
  }
}
