import 'package:flutter/material.dart';

class VSpacing {
  VSpacing._();
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}

class VRadius {
  VRadius._();
  static const double xxs = 2;
  static const double none = 0;
  static const double xs = 4;
  /// Commune card radius — 8px (DCX-029).
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 18;
  static const double xxl = 20;
  static const double xxxl = 24;
  /// Pill buttons and chips (DCX-029).
  static const double pill = 9999;

  static const double communeCard = sm;
  static const double communeButton = pill;
}

class VIconSize {
  VIconSize._();
  static const double xs = 12;
  static const double denseSm = 14;
  static const double sm = 16;
  static const double base = 18;
  static const double md = 20;
  static const double lgMd = 22;
  static const double lg = 24;
  static const double xl = 32;

  /// Dense list icon steps for channel rows (DCX-038): 20 / 16 / 14.
  static const double denseLg = 20;
  static const double denseMd = 16;
}

/// Raster profession / achievement badge display sizes (~10% above legacy defaults).
class VBadgeSize {
  VBadgeSize._();

  /// Default list / profile / unlock row badge.
  static const double avatar = 52;

  /// Dense grids (reaction picker, recent chips).
  static const double avatarCompact = 48;

  /// Proof / detail sheet / share card hero badge.
  static const double avatarSheet = 72;

  static const double categoryAvatar = 52;
  static const double profession = 28;
  static const double professionInline = 24;
  static const double decorationChip = 28;

  /// Fraction of the slot used for raster art (rest is even padding).
  static const double artFillFraction = 0.94;

  /// Material icon fallback inside the badge slot.
  static const double fallbackIconFraction = 0.58;

  static double artInset(double size) =>
      size * (1 - artFillFraction) / 2;

  static double artInner(double size) => size * artFillFraction;
}

class VAnimation {
  VAnimation._();
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration entrance = Duration(milliseconds: 500);
  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasized = Curves.easeInOutCubicEmphasized;
  static const Curve spring = Curves.elasticOut;
}

class VTouchTarget {
  VTouchTarget._();
  static const double minimum = 48;
  static const double iconButton = 40;
  static const double chip = 32;
}

class VFont {
  VFont._();
  static const String sans = 'PlusJakartaSans';
  static const String mono = 'JetBrainsMono';
  static const String headline = 'PlusJakartaSans';
}

class VFontWeight {
  VFontWeight._();
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight extraBold = FontWeight.w800;
}

class VFontSize {
  VFontSize._();
  static const double displayXl = 32;
  static const double displayLg = 26;
  static const double headlineLg = 24;
  static const double headlineMd = 20;
  static const double headlineSm = 18;
  static const double bodyLg = 16;
  static const double bodyMd = 14;
  static const double bodySm = 13;
  static const double labelLg = 14;
  static const double labelMd = 12;
  static const double labelSm = 11;
}

class VLineHeight {
  VLineHeight._();
  static const double display = 1.15;
  static const double headline = 1.25;
  static const double body = 1.4;
  static const double bodyLg = 1.5;
  static const double label = 1.0;
}

/// Chat message text roles (DCX-027).
enum VChatTextRole { normal, muted, headerPrimary, headerSecondary, link, mention }

class VChatText {
  VChatText._();
}

class VShadow {
  VShadow._();
  static const List<BoxShadow> sm = [
    BoxShadow(
      color: Color(0x0A000000),
      offset: Offset(0, 1),
      blurRadius: 2,
    ),
  ];
  static const List<BoxShadow> md = [
    BoxShadow(
      color: Color(0x0F000000),
      offset: Offset(0, 2),
      blurRadius: 4,
    ),
    BoxShadow(
      color: Color(0x08000000),
      offset: Offset(0, 4),
      blurRadius: 8,
    ),
  ];
  static const List<BoxShadow> lg = [
    BoxShadow(
      color: Color(0x14000000),
      offset: Offset(0, 4),
      blurRadius: 8,
    ),
    BoxShadow(
      color: Color(0x0A000000),
      offset: Offset(0, 8),
      blurRadius: 16,
    ),
  ];
  static const List<BoxShadow> xl = [
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 8),
      blurRadius: 16,
    ),
    BoxShadow(
      color: Color(0x0F000000),
      offset: Offset(0, 16),
      blurRadius: 32,
    ),
  ];
}

class VBreakpoint {
  VBreakpoint._();
  static const double phone = 600;
  static const double tablet = 840;
  static const double desktop = 1200;
}

class VMagicNumbers {
  VMagicNumbers._();
  static const councilRepThreshold = 5000;
  static const postTruncateLength = 280;
  static const tabBarHeight = 56.0;
  static const gridAspectRatio = 0.75;
  static const scheduledPostPastGraceMinutes = 5;
}
