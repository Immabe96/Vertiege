import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'v_motion.dart';

/// Consistent haptic feedback on iOS and Android (respects reduced motion).
class VHaptics {
  VHaptics._();

  static bool _enabled(BuildContext context) =>
      context.motionEnabled;

  static void lightImpact(BuildContext context) {
    if (!_enabled(context)) return;
    HapticFeedback.lightImpact();
  }

  static void mediumImpact(BuildContext context) {
    if (!_enabled(context)) return;
    HapticFeedback.mediumImpact();
  }

  static void selectionClick(BuildContext context) {
    if (!_enabled(context)) return;
    HapticFeedback.selectionClick();
  }

  static void success(BuildContext context) {
    if (!_enabled(context)) return;
    HapticFeedback.mediumImpact();
  }
}
