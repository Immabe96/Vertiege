// @deprecated
// This file is a compatibility shim. Migrate imports to 'v_tokens.dart' directly.
// Spacing, RadiusTokens, IconSizes, etc. are re-exported from v_tokens.dart.
// This file will be removed in a future version.
import 'package:flutter/material.dart';
import 'v_tokens.dart';
export 'v_tokens.dart';

/// Backward-compatible aliases for design tokens
/// TODO: Migrate all usages to VSpacing, VRadius, etc., then remove this file
class Spacing {
  Spacing._();
  static const double xs = VSpacing.xs;
  static const double sm = VSpacing.sm;
  static const double md = VSpacing.md;
  static const double lg = VSpacing.lg;
  static const double xl = VSpacing.xl;
  static const double xxl = VSpacing.xxl;
  static const double section = VSpacing.xxl;
  static const double gutter = VSpacing.md;
  static const double marginMobile = VSpacing.lg;
  static const double marginDesktop = VSpacing.xxl;
}

class RadiusTokens {
  RadiusTokens._();
  static const double sm = VRadius.sm;
  static const double md = VRadius.md;
  static const double lg = VRadius.lg;
  static const double xl = VRadius.xl;
  static const double card = VRadius.lg;
  static const double cardFeatured = VRadius.md;
  static const double input = VRadius.md;
  static const double chip = VRadius.sm;
  static const double full = VRadius.pill;
  static const double pill = VRadius.pill;
}

class IconSizes {
  IconSizes._();
  static const double xs = VIconSize.xs;
  static const double sm = VIconSize.sm;
  static const double md = VIconSize.md;
  static const double lg = VIconSize.lg;
  static const double xl = VIconSize.xl;
  static const double hero = VIconSize.xl;
}

class AnimDurations {
  AnimDurations._();
  static const Duration fast = VAnimation.fast;
  static const Duration normal = VAnimation.normal;
  static const Duration slow = VAnimation.slow;
  static const Duration entrance = VAnimation.entrance;
}

class AnimCurves {
  AnimCurves._();
  static const Curve standard = VAnimation.standard;
  static const Curve emphasized = VAnimation.emphasized;
  static const Curve spring = VAnimation.spring;
  static const Curve easeOut = Curves.easeOutCubic;
  static const Curve easeInOut = Curves.easeInOutCubic;
  static const Curve bouncy = Curves.elasticOut;
}

class TouchTargets {
  TouchTargets._();
  static const double minimum = VTouchTarget.minimum;
  static const double iconButton = VTouchTarget.iconButton;
  static const double chip = VTouchTarget.chip;
}

class AppFont {
  AppFont._();
  static const String sans = VFont.sans;
  static const String mono = VFont.mono;
  static const String headline = VFont.headline;
}

class FontWeights {
  FontWeights._();
  static const FontWeight regular = VFontWeight.regular;
  static const FontWeight semiBold = VFontWeight.semiBold;
  static const FontWeight bold = VFontWeight.bold;
}

class FontSizes {
  FontSizes._();
  static const double labelXs = VFontSize.labelSm;
  static const double labelSm = VFontSize.labelMd;
  static const double labelMd = VFontSize.labelLg;
  static const double bodySm = VFontSize.bodySm;
  static const double bodyMd = VFontSize.bodyMd;
  static const double bodyLg = VFontSize.bodyLg;
  static const double headlineSm = VFontSize.headlineSm;
  static const double headlineMd = VFontSize.headlineMd;
  static const double headlineLg = VFontSize.headlineLg;
  static const double displayXl = VFontSize.displayXl;
  static const double micro = labelXs;
  static const double caption = labelSm;
  static const double body = bodyMd;
  static const double headingCard = headlineMd;
  static const double displayHero = displayXl;
}

class LetterSpacing {
  LetterSpacing._();
  static const double display = 0.0;
  static const double headline = 0.0;
  static const double normal = 0.0;
  static const double label = 0.0;
  static const double section = headline;
  static const double micro = label;
}

class LineHeight {
  LineHeight._();
  static const double display = VLineHeight.display;
  static const double headline = VLineHeight.headline;
  static const double headlineLg = VLineHeight.headline;
  static const double body = VLineHeight.body;
  static const double bodyLg = VLineHeight.bodyLg;
  static const double label = VLineHeight.label;
  static const double button = label;
}
