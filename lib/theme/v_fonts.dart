import 'package:flutter/material.dart';

/// Typography tokens — system sans for now so login never sync-loads Google Fonts.
///
/// Plus Jakarta via `google_fonts` can be re-enabled with bundled assets once
/// startup profiling is clean on device.
class VFonts {
  VFonts._();

  static const String sansFamily = 'sans-serif';

  static Future<void> ensureLoaded() async {}

  static TextStyle sans({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    FontStyle? fontStyle,
    double? letterSpacing,
  }) =>
      TextStyle(
        fontFamily: sansFamily,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        fontStyle: fontStyle,
        letterSpacing: letterSpacing,
      );

  static TextTheme apply(TextTheme theme) => theme;
}
