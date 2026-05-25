import 'package:flutter/material.dart';

import '../../theme/v_colors.dart';

/// Circle behind badge art. Transparent PNGs use no fill; icon fallbacks keep a tint.
Color achievementBadgeContainerColor({
  required bool hasRasterAsset,
  required Color accent,
  required Brightness brightness,
}) {
  if (hasRasterAsset) return Colors.transparent;
  return achievementAvatarFill(accent, brightness);
}

/// Fill behind achievement/category icon fallback — readable on AMOLED dark UI.
Color achievementAvatarFill(Color accent, Brightness brightness) {
  return accent.withValues(
    alpha: brightness == Brightness.dark ? 0.28 : 0.14,
  );
}

/// Pill/chip background for verified achievement labels on dark theme.
Color achievementChipBackground(Brightness brightness) {
  return brightness == Brightness.dark
      ? VColors.surfaceContainerHighDark
      : VColors.tertiary.withValues(alpha: 0.12);
}

Color achievementChipBorder(Brightness brightness) {
  return brightness == Brightness.dark
      ? VColors.tertiary.withValues(alpha: 0.5)
      : VColors.tertiary.withValues(alpha: 0.25);
}
