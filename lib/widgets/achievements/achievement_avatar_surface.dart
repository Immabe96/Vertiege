import 'package:flutter/material.dart';

import '../../theme/v_colors.dart';

/// Fill behind achievement labels/chips (not badge raster art).
Color achievementAvatarFill(Color accent, Brightness brightness) {
  return accent.withValues(alpha: 0.28);
}

/// Pill/chip background for verified achievement labels on dark theme.
Color achievementChipBackground(Brightness brightness) {
  return VColors.surfaceContainerHighDark;
}

Color achievementChipBorder(Brightness brightness) {
  return VColors.tertiary.withValues(alpha: 0.5);
}
