import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography wiring — tokens name Plus Jakarta; this applies it app-wide.
class VFonts {
  VFonts._();

  static String get sansFamily => GoogleFonts.plusJakartaSans().fontFamily!;

  static TextStyle sans({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    FontStyle? fontStyle,
    double? letterSpacing,
  }) =>
      GoogleFonts.plusJakartaSans(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        fontStyle: fontStyle,
        letterSpacing: letterSpacing,
      );

  static TextTheme apply(TextTheme theme) =>
      GoogleFonts.plusJakartaSansTextTheme(theme);
}
