import 'package:flutter/material.dart';
import '../theme/v_colors.dart';

/// Maps standing level to a tier-appropriate color for the standing badge.
Color tierStandingColor(int level) {
  switch (level) {
    case 1:
      return VColors.tierHustler;
    case 2:
      return VColors.tierHighRoller;
    case 3:
      return VColors.tierElite;
    case 4:
      return VColors.tierOldMoney;
    case 5:
      return VColors.tierApex;
    case 6:
      return VColors.tertiary;
    case 7:
      return VColors.primary;
    default:
      return VColors.outline;
  }
}
