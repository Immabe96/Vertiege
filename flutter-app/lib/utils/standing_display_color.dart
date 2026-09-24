import 'package:flutter/material.dart';

import '../config/tiers.dart';
import '../theme/v_colors.dart';

/// World standing tint for resident display names in chat.
Color standingDisplayColor(
  int rep, {
  String? sovereignId,
  String? residentId,
  Brightness brightness = Brightness.dark,
}) {
  if (sovereignId != null && residentId == sovereignId) {
    return VColors.tertiary;
  }
  final muted = brightness == Brightness.dark
      ? const Color(0xFFB5BAC1)
      : const Color(0xFF6D7278);
  final level = getStanding(rep).level;
  return switch (level) {
    7 => VColors.tertiary,
    6 => const Color(0xFFE8A54B),
    5 => const Color(0xFF9B7EDE),
    4 => VColors.primary,
    3 => const Color(0xFF57A5FF),
    2 => muted,
    _ => muted,
  };
}
