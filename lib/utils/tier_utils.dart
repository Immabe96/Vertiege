import 'package:flutter/material.dart';
import '../theme/colors.dart';

/// Maps standing level to a tier-appropriate color for the standing badge.
Color tierStandingColor(int level) {
  switch (level) {
    case 1:
      return AppColors.tierHustler;
    case 2:
      return AppColors.tierHighRoller;
    case 3:
      return AppColors.tierElite;
    case 4:
      return AppColors.tierOldMoney;
    case 5:
      return AppColors.tierApex;
    case 6:
      return AppColors.tertiary;
    case 7:
      return AppColors.primary;
    default:
      return AppColors.inkMuted;
  }
}
