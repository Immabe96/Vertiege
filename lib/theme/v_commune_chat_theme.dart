import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import 'v_colors.dart';
import 'v_commune_colors.dart';
import 'v_fonts.dart';
import 'v_tokens.dart';

/// Commune channel chat theming — bubbles, markdown, and system pills.
abstract final class VCommuneChatTheme {
  static Color backgroundColorOf(Brightness brightness) =>
      VCommuneColors.surfacePrimaryOf(brightness);

  static Color receivedBubbleColorOf(Brightness brightness) =>
      VCommuneColors.surfaceSecondaryOf(brightness);

  static Color get sentBubbleColor => VColors.brand;

  static Color receivedTextColorOf(Brightness brightness) =>
      VCommuneColors.textNormalOf(brightness);

  static Color get sentTextColor => VColors.onBrand;

  static Color timestampMutedOf(Brightness brightness) =>
      VCommuneColors.textMutedOf(brightness);

  static Color linkColorOf(Brightness brightness) =>
      VCommuneColors.textLinkOf(brightness);

  /// @mention highlight — brand accent, distinct from URLs (DCX-034).
  static Color get mentionColor => VCommuneColors.textMention;

  // Legacy dark-only getters (prefer *Of methods in new code).
  static Color get backgroundColor => VCommuneColors.surfacePrimary;
  static Color get receivedBubbleColor => VCommuneColors.surfaceSecondary;
  static Color get receivedTextColor => VCommuneColors.textNormal;
  static Color get timestampMuted => VCommuneColors.textMuted;
  static Color get linkColor => VCommuneColors.textLink;

  static TextStyle messageBody({Brightness brightness = Brightness.dark}) =>
      VFonts.chat(role: VChatTextRole.normal, brightness: brightness);

  static TextStyle messageHeader({Brightness brightness = Brightness.dark}) =>
      VFonts.chat(role: VChatTextRole.headerPrimary, brightness: brightness);

  static TextStyle messageMuted({Brightness brightness = Brightness.dark}) =>
      VFonts.chat(role: VChatTextRole.muted, brightness: brightness);

  /// Discord-like asymmetric corners for incoming messages.
  static const BorderRadius receivedBorderRadius = BorderRadius.only(
    topRight: Radius.circular(VRadius.lg),
    bottomRight: Radius.circular(VRadius.lg),
    bottomLeft: Radius.circular(VRadius.lg),
    topLeft: Radius.circular(VRadius.sm),
  );

  /// Discord-like asymmetric corners for outgoing messages.
  static const BorderRadius sentBorderRadius = BorderRadius.only(
    topLeft: Radius.circular(VRadius.lg),
    topRight: Radius.circular(VRadius.lg),
    bottomLeft: Radius.circular(VRadius.lg),
    bottomRight: Radius.circular(VRadius.sm),
  );

  static MarkdownStyleSheet markdownStyle({
    required Color textColor,
    required Brightness brightness,
  }) {
    final link = linkColorOf(brightness);
    return MarkdownStyleSheet(
      p: TextStyle(
        fontSize: VFontSize.bodyMd,
        color: textColor,
        height: VLineHeight.body,
      ),
      code: TextStyle(
        fontSize: VFontSize.bodyMd - 2,
        color: textColor,
        backgroundColor: textColor.withValues(alpha: 0.1),
        fontFamily: 'monospace',
      ),
      codeblockDecoration: BoxDecoration(
        color: textColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(VRadius.md),
        border: Border.all(color: textColor.withValues(alpha: 0.15)),
      ),
      a: TextStyle(
        fontSize: VFontSize.bodyMd,
        color: link,
        decoration: TextDecoration.underline,
      ),
      blockquoteDecoration: BoxDecoration(
        border: Border(left: BorderSide(color: link, width: 3)),
        color: link.withValues(alpha: 0.05),
      ),
      h1: TextStyle(
        fontSize: VFontSize.headlineMd,
        fontWeight: VFontWeight.bold,
        color: textColor,
      ),
      h2: TextStyle(
        fontSize: VFontSize.bodyLg,
        fontWeight: VFontWeight.bold,
        color: textColor,
      ),
      h3: TextStyle(
        fontSize: VFontSize.bodyMd,
        fontWeight: VFontWeight.semiBold,
        color: textColor,
      ),
    );
  }

  /// Centered system-message pill (join/leave, pins, etc.).
  static BoxDecoration systemMessageDecorationOf(Brightness brightness) =>
      BoxDecoration(
        color: VCommuneColors.surfaceSecondaryAltOf(brightness),
        borderRadius: BorderRadius.circular(VRadius.pill),
      );

  static BoxDecoration get systemMessageDecoration => BoxDecoration(
    color: VCommuneColors.surfaceSecondaryAlt,
    borderRadius: BorderRadius.circular(VRadius.pill),
  );
}
