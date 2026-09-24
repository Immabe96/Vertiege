import 'package:flutter/material.dart';

import '../utils/v_motion.dart';
import 'v_tokens.dart';

export 'v_tokens.dart' show VAnimation;
export '../utils/v_motion.dart' show VMotionContext;

/// Animation helpers that respect system reduced-motion ([MediaQuery.disableAnimations]).
abstract final class VMotion {
  VMotion._();

  static bool enabled(BuildContext context) => context.motionEnabled;

  static Duration duration(
    BuildContext context,
    Duration normal, {
    Duration reduced = Duration.zero,
  }) =>
      context.motionDuration(normal, reduced: reduced);

  static Curve curve(BuildContext context) => context.motionCurve;

  /// Panel slide / fade — used by [VOverlappingPanels].
  static Duration panel(BuildContext context) =>
      duration(context, VAnimation.normal);

  static Duration fast(BuildContext context) =>
      duration(context, VAnimation.fast);

  static Duration slow(BuildContext context) =>
      duration(context, VAnimation.slow);
}
