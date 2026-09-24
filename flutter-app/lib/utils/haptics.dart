import 'package:flutter/services.dart';

/// Curated haptic feedback library for Vertiege interactions.
/// Each method maps to a specific user moment for a consistent feel.
class Haptics {
  Haptics._();

  /// Subtle tap — reaction button, checkbox, small toggles.
  static void light() => HapticFeedback.lightImpact();

  /// Confirmed action — post send, join, submit.
  static void medium() => HapticFeedback.mediumImpact();

  /// High-impact moment — achievement unlock, tier up.
  static void heavy() => HapticFeedback.heavyImpact();

  /// Discrete selection — tab switch, filter change.
  static void selection() => HapticFeedback.selectionClick();

  /// Double-tap feel for major achievements / tier promotions.
  static void success() {
    heavy();
    Future.delayed(const Duration(milliseconds: 100), heavy);
  }
}
