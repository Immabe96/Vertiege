import 'package:flutter/material.dart';

import 'v_commune_colors.dart';
import 'v_tokens.dart';

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

  /// Commune chat typography by role (DCX-027).
  static TextStyle chat({
    required VChatTextRole role,
    Brightness brightness = Brightness.dark,
    double? fontSize,
    FontWeight? fontWeight,
  }) {
    final isDark = brightness == Brightness.dark;
    final color = switch (role) {
      VChatTextRole.normal => isDark
          ? VCommuneColors.textNormal
          : VCommuneColors.textNormalLight,
      VChatTextRole.muted => isDark
          ? VCommuneColors.textMuted
          : VCommuneColors.textMutedLight,
      VChatTextRole.headerPrimary => isDark
          ? VCommuneColors.headerPrimary
          : VCommuneColors.headerPrimaryLight,
      VChatTextRole.headerSecondary => isDark
          ? VCommuneColors.headerSecondary
          : VCommuneColors.headerSecondaryLight,
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
