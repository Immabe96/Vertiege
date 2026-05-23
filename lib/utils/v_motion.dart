import 'package:flutter/material.dart';

import '../theme/v_tokens.dart';

/// Respects system reduced-motion / [MediaQuery.disableAnimations].
extension VMotionContext on BuildContext {
  bool get motionEnabled => !MediaQuery.disableAnimationsOf(this);

  Duration motionDuration(
    Duration normal, {
    Duration reduced = Duration.zero,
  }) {
    return motionEnabled ? normal : reduced;
  }

  Curve get motionCurve =>
      motionEnabled ? VAnimation.standard : Curves.linear;
}
