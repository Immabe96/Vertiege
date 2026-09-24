import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'v_commune_colors.dart';
import 'v_tokens.dart';

/// Typography — Plus Jakarta Sans (Prestige Noir brand).
class VFonts {
  VFonts._();

  static const String sansFamily = 'Plus Jakarta Sans';

  /// Prefetch weights used across the app before first frame.
  static Future<void> ensureLoaded() async {
    await GoogleFonts.pendingFonts([
      GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w400),
      GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500),
      GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
      GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
    ]);
  }

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

  /// Commune chat typography by role (DCX-027).
  static TextStyle chat({
    required VChatTextRole role,
    Brightness brightness = Brightness.dark,
    double? fontSize,
    FontWeight? fontWeight,
  }) {
    final color = switch (role) {
      VChatTextRole.normal => VCommuneColors.textNormal,
      VChatTextRole.muted => VCommuneColors.textMuted,
      VChatTextRole.headerPrimary => VCommuneColors.headerPrimary,
      VChatTextRole.headerSecondary => VCommuneColors.headerSecondary,
      VChatTextRole.link => VCommuneColors.textLinkOf(brightness),
      VChatTextRole.mention => VCommuneColors.textMention,
    };
    final weight = fontWeight ??
        switch (role) {
          VChatTextRole.headerPrimary => VFontWeight.semiBold,
          VChatTextRole.mention => VFontWeight.semiBold,
          _ => VFontWeight.regular,
        };
    final size = fontSize ??
        switch (role) {
          VChatTextRole.headerPrimary => VFontSize.bodyMd,
          VChatTextRole.headerSecondary => VFontSize.labelMd,
          _ => VFontSize.bodyMd,
        };
    return sans(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: VLineHeight.body,
    );
  }
}
