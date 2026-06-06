import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';

import 'v_colors.dart';
import 'v_commune_colors.dart';
import 'v_fonts.dart';

class VertiegeForuiTheme {
  VertiegeForuiTheme._();

  static FThemeData get light => _build(isDark: false, commune: false);
  static FThemeData get dark => _build(isDark: true, commune: false);
  static FThemeData get lightCommune => _build(isDark: false, commune: true);
  static FThemeData get darkCommune => _build(isDark: true, commune: true);

  static FThemeData forPreset({required bool isDark, required bool commune}) =>
      _build(isDark: isDark, commune: commune);

  static FThemeData _build({required bool isDark, required bool commune}) {
    final bg = commune
        ? VCommuneColors.surfacePrimaryOf(
            isDark ? Brightness.dark : Brightness.light,
          )
        : (isDark ? VColors.surfaceDark : VColors.surface);
    final fg = commune
        ? VCommuneColors.textNormalOf(
            isDark ? Brightness.dark : Brightness.light,
          )
        : (isDark ? VColors.onSurfaceDark : VColors.onSurface);
    final card = commune
        ? (isDark
              ? VCommuneColors.surfaceSecondary
              : VCommuneColors.surfaceSecondaryLight)
        : (isDark
              ? VColors.surfaceContainerDark
              : VColors.surfaceContainerLowest);
    final muted = commune
        ? (isDark
              ? VCommuneColors.surfaceTertiary
              : VCommuneColors.surfaceTertiaryLight)
        : (isDark ? VColors.surfaceContainerDark : VColors.surfaceContainer);
    final mutedFg = commune
        ? VCommuneColors.textMutedOf(
            isDark ? Brightness.dark : Brightness.light,
          )
        : (isDark ? VColors.onSurfaceVariantDark : VColors.onSurfaceVariant);
    final border = commune
        ? VCommuneColors.dividerOf(
            isDark ? Brightness.dark : Brightness.light,
          )
        : (isDark ? VColors.outlineVariantDark : VColors.outlineVariant);

    final colors = FColors(
      brightness: isDark ? Brightness.dark : Brightness.light,
      systemOverlayStyle: isDark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      barrier: isDark ? const Color(0xAA000000) : const Color(0x33000000),
      background: bg,
      foreground: fg,
      primary: isDark ? VColors.brandLight : VColors.brand,
      primaryForeground: VColors.onBrand,
      secondary: isDark
          ? (commune
                ? VCommuneColors.surfaceSecondaryAlt
                : VColors.surfaceContainerHighDark)
          : (commune
                ? VCommuneColors.surfaceSecondaryAltLight
                : VColors.surfaceContainerLow),
      secondaryForeground: fg,
      muted: muted,
      mutedForeground: mutedFg,
      destructive: VColors.error,
      destructiveForeground: VColors.onError,
      error: VColors.error,
      errorForeground: VColors.onError,
      card: card,
      border: border,
    );

    return FThemeData(
      debugLabel: commune
          ? (isDark ? 'Vertiege Commune Dark' : 'Vertiege Commune Light')
          : (isDark ? 'Vertiege Prestige Noir' : 'Vertiege Light Forui'),
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
            sm: TextStyle(
              fontSize: 14,
              height: 1.35,
              color: fg,
            ),
            md: TextStyle(
              fontSize: 16,
              height: 1.45,
              color: fg,
            ),
            lg: const TextStyle(fontSize: 18, height: 1.35),
            xl: const TextStyle(fontSize: 20, height: 1.3),
            xl2: const TextStyle(fontSize: 24, height: 1.25),
            xl3: const TextStyle(fontSize: 28, height: 1.2),
          ),
    );
  }
}
