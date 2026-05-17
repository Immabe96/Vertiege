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
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 28;
  static const double pill = 9999;
}

class VIconSize {
  VIconSize._();
  static const double xs = 12;
  static const double sm = 16;
  static const double md = 20;
  static const double lg = 24;
  static const double xl = 32;
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
  static const double displayXl = 36;
  static const double displayLg = 28;
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
