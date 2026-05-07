import 'package:flutter/material.dart';

/// Vertiege design tokens — Sovereign Excellence
/// Source: Stitch design system "App Interface Redesign"

// ── Font ────────────────────────────────────────────────────
class AppFont {
  AppFont._();
  static const String headline = 'Space Grotesk';
  static const String body = 'Inter';
  static const String mono = 'JetBrains Mono';
}

// ── Typography Scale ────────────────────────────────────────
class FontSizes {
  FontSizes._();
  static const double labelSm = 12;
  static const double bodyMd = 16;
  static const double bodyLg = 18;
  static const double headlineMd = 24;
  static const double headlineLg = 32;
  static const double displayXl = 48;

  // Legacy aliases
  static const double micro = labelSm;
  static const double caption = labelSm;
  static const double body = bodyMd;
  static const double headingCard = headlineMd;
  static const double displayHero = displayXl;
}

class FontWeights {
  FontWeights._();
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
}

class LetterSpacing {
  LetterSpacing._();
  static const double display = -0.02;
  static const double headline = -0.01;
  static const double normal = 0.0;
  static const double label = 0.05;

  // Legacy aliases
  static const double section = headline;
  static const double micro = label;
}

class LineHeight {
  LineHeight._();
  static const double display = 1.1;
  static const double headline = 1.3;
  static const double headlineLg = 1.2;
  static const double body = 1.5;
  static const double bodyLg = 1.6;
  static const double label = 1.0;

  // Legacy aliases
  static const double button = label;
}

// ── Spacing Scale (8px base) ────────────────────────────────
class Spacing {
  Spacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double section = 48;
  static const double gutter = 24;
  static const double marginMobile = 16;
  static const double marginDesktop = 40;
}

// ── Radius Scale (architectural — tight) ────────────────────
class RadiusTokens {
  RadiusTokens._();
  static const double sm = 2;
  static const double md = 4;
  static const double lg = 6;
  static const double xl = 8;
  static const double full = 12;

  // Legacy aliases
  static const double chip = lg;
  static const double input = md;
  static const double card = xl;
  static const double cardFeatured = full;
  static const double celebration = full;
  static const double pill = 9999;
  static const double circle = 9999;
}

// ── Icon Sizes ──────────────────────────────────────────────
class IconSizes {
  IconSizes._();
  static const double xs = 12;
  static const double sm = 14;
  static const double md = 20;
  static const double lg = 24;
  static const double xl = 32;
  static const double hero = 48;
}

// ── Animation ───────────────────────────────────────────────
class AnimDurations {
  AnimDurations._();
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration entrance = Duration(milliseconds: 500);
}

class AnimCurves {
  AnimCurves._();
  static const Curve easeOut = Curves.easeOutCubic;
  static const Curve easeInOut = Curves.easeInOutCubic;
  static const Curve spring = Curves.elasticOut;
  static const Curve bouncy = Curves.easeOutBack;
}

// ── Touch Targets ───────────────────────────────────────────
class TouchTargets {
  TouchTargets._();
  static const double minimum = 44;
  static const double iconButton = 40;
  static const double chip = 32;
}

// ── World Icon Map ──────────────────────────────────────────
const Map<String, IconData> worldIconMap = {
  'public': Icons.public,
  'landscape': Icons.landscape,
  'science': Icons.science,
  'account_balance': Icons.account_balance,
  'rocket': Icons.rocket,
  'palette': Icons.palette,
  'music_note': Icons.music_note,
  'code': Icons.code,
  'earth': Icons.public,
};
