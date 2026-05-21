import 'package:flutter/material.dart';
import '../theme/v_colors.dart';

enum LegacyTier { none, bronze, silver, gold, diamond }

extension LegacyTierExtension on LegacyTier {
  String get label {
    switch (this) {
      case LegacyTier.diamond:
        return 'DIAMOND';
      case LegacyTier.gold:
        return 'GOLD';
      case LegacyTier.silver:
        return 'SILVER';
      case LegacyTier.bronze:
        return 'BRONZE';
      case LegacyTier.none:
        return '';
    }
  }

  Color get color {
    switch (this) {
      case LegacyTier.diamond:
        return VColors.primary;
      case LegacyTier.gold:
        return VColors.tertiary;
      case LegacyTier.silver:
        return VColors.outline;
      case LegacyTier.bronze:
        return VColors.outlineVariant;
      case LegacyTier.none:
        return Colors.transparent;
    }
  }
}

class LegacyService {
  LegacyService._();

  static LegacyTier calculateLegacy(int prestige, DateTime createdAt) {
    final ageInDays = DateTime.now().difference(createdAt).inDays;
    if (prestige >= 1000 && ageInDays >= 365) return LegacyTier.diamond;
    if (prestige >= 700 && ageInDays >= 180) return LegacyTier.gold;
    if (prestige >= 400 && ageInDays >= 90) return LegacyTier.silver;
    if (prestige >= 200 && ageInDays >= 30) return LegacyTier.bronze;
    return LegacyTier.none;
  }

  /// Format the founded date for display, e.g. "Est. June 2025"
  static String formatFoundedDate(DateTime createdAt) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return 'Est. ${months[createdAt.month - 1]} ${createdAt.year}';
  }
}
