import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';

import 'v_colors.dart';
import 'v_fonts.dart';
import 'v_tokens.dart';
import 'prestige_noir.dart';

class VertiegeForuiTheme {
  VertiegeForuiTheme._();

  /// Prestige Noir — sole app theme (dark-only).
  static FThemeData get dark => _build();

  /// Legacy aliases — all resolve to Prestige Noir dark.
  static FThemeData get light => dark;
  static FThemeData get lightCommune => dark;
  static FThemeData get darkCommune => dark;

  @Deprecated('App is dark-only Prestige Noir')
  static FThemeData forPreset({required bool isDark, required bool commune}) =>
      dark;

  static FThemeData _build() {
    const bg = PrestigeNoir.bg;
    const fg = PrestigeNoir.foreground;
    const card = PrestigeNoir.surface;
    const muted = PrestigeNoir.surfaceRaised;
    const mutedFg = PrestigeNoir.muted;
    const border = PrestigeNoir.borderLight;

    final colors = FColors(
      brightness: Brightness.dark,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      barrier: const Color(0xAA000000),
      background: bg,
      foreground: fg,
      primary: VColors.brand,
      primaryForeground: VColors.onBrand,
      secondary: PrestigeNoir.surfaceRaised,
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
      debugLabel: 'Vertiege Prestige Noir',
      colors: colors,
      touch: true,
      typography:
          FTypography.inherit(
            colors: colors,
            touch: false,
            fontFamily: VFonts.sansFamily,
          ).copyWith(
            // Aligned with VFontSize / VLineHeight (single type scale).
            xs3: const TextStyle(fontSize: 9, height: VLineHeight.label),
            xs2: const TextStyle(
              fontSize: VFontSize.labelSm,
              height: VLineHeight.label,
            ),
            xs: const TextStyle(fontSize: VFontSize.labelMd, height: 1.15),
            sm: TextStyle(
              fontSize: VFontSize.bodyMd,
              height: VLineHeight.body,
              color: fg,
            ),
            md: TextStyle(
              fontSize: VFontSize.bodyLg,
              height: VLineHeight.bodyLg,
              color: fg,
            ),
            lg: const TextStyle(
              fontSize: VFontSize.headlineSm,
              height: VLineHeight.headline,
            ),
            xl: const TextStyle(
              fontSize: VFontSize.headlineMd,
              height: VLineHeight.headline,
            ),
            xl2: const TextStyle(
              fontSize: VFontSize.headlineLg,
              height: VLineHeight.headline,
            ),
            xl3: const TextStyle(
              fontSize: VFontSize.displayLg,
              height: VLineHeight.display,
            ),
          ),
    );
  }
}
