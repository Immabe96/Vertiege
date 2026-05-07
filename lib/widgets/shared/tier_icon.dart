import 'package:flutter/material.dart';
import '../../theme/colors.dart';

class TierIcon extends StatelessWidget {
  final int tier;
  final double size;

  const TierIcon({super.key, required this.tier, this.size = 24});

  @override
  Widget build(BuildContext context) {
    final icon = switch (tier) {
      5 => Icons.flag,
      4 => Icons.shield,
      3 => Icons.local_police,
      2 => Icons.diamond,
      _ => Icons.trending_up,
    };
    final color = switch (tier) {
      5 => AppColors.tierApex,
      4 => AppColors.tierOldMoney,
      3 => AppColors.tierElite,
      2 => AppColors.tierHighRoller,
      _ => AppColors.tierHustler,
    };

    return Icon(icon, size: size, color: color);
  }
}
