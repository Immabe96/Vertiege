import 'package:flutter/material.dart';

class Spacing {
  Spacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

class RadiusTokens {
  RadiusTokens._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 28;
  static const double round = 100;
}

class FontSizes {
  FontSizes._();
  static const double caption = 12;
  static const double body = 14;
  static const double bodyLarge = 16;
  static const double subhead = 18;
  static const double title = 22;
  static const double headline = 28;
  static const double hero = 36;
}

class FontWeights {
  FontWeights._();
  static const regular = 400;
  static const medium = 500;
  static const semibold = 600;
  static const bold = 700;
}

class LetterSpacing {
  LetterSpacing._();
  static const double tight = -0.5;
  static const double normal = 0.0;
  static const double wide = 0.5;
  static const double heading = -1.5;
}

class LineHeight {
  LineHeight._();
  static const double tight = 1.1;
  static const double normal = 1.4;
  static const double relaxed = 1.6;
}

class IconSizes {
  IconSizes._();
  static const double xs = 12;
  static const double sm = 14;
  static const double md = 20;
  static const double lg = 28;
  static const double xl = 48;
  static const double hero = 64;
}

class BorderWidth {
  BorderWidth._();
  static const double thin = 0.5;
  static const double normal = 1.0;
  static const double thick = 2.0;
  static const double accent = 3.0;
}

class ShadowTokens {
  ShadowTokens._();
  static const xs = <BoxShadow>[
    BoxShadow(color: Color(0x08000000), blurRadius: 2, offset: Offset(0, 1)),
  ];
  static const sm = <BoxShadow>[
    BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 2)),
  ];
  static const md = <BoxShadow>[
    BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 4)),
  ];
  static const lg = <BoxShadow>[
    BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 8)),
  ];
  static const xl = <BoxShadow>[
    BoxShadow(color: Color(0x1A000000), blurRadius: 24, offset: Offset(0, 12)),
  ];
  static const glow = <BoxShadow>[
    BoxShadow(color: Color(0x30000000), blurRadius: 32, offset: Offset(0, 0)),
  ];

  static const darkXs = <BoxShadow>[
    BoxShadow(color: Color(0x12000000), blurRadius: 2, offset: Offset(0, 1)),
  ];
  static const darkMd = <BoxShadow>[
    BoxShadow(color: Color(0x20000000), blurRadius: 8, offset: Offset(0, 4)),
  ];
  static const darkGlow = <BoxShadow>[
    BoxShadow(color: Color(0x40000000), blurRadius: 32, offset: Offset(0, 0)),
  ];
}

class AnimDurations {
  AnimDurations._();
  static const Duration instant = Duration(milliseconds: 80);
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration entrance = Duration(milliseconds: 500);
  static const Duration dramatic = Duration(milliseconds: 800);
}

class AnimCurves {
  AnimCurves._();
  static const Curve easeOut = Curves.easeOutCubic;
  static const Curve easeInOut = Curves.easeInOutCubic;
  static const Curve spring = Curves.elasticOut;
  static const Curve bouncy = Curves.easeOutBack;
}
