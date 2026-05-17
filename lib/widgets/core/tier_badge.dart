import 'package:flutter/material.dart';
import '../../theme/v_colors.dart';

class TierBadge extends StatelessWidget {
  final int tier;
  final double size;

  const TierBadge({super.key, required this.tier, this.size = 16});

  Color get _color {
    switch (tier) {
      case 5:
        return VColors.tierApex;
      case 4:
        return VColors.tierOldMoney;
      case 3:
        return VColors.tierElite;
      case 2:
        return VColors.tierHighRoller;
      default:
        return VColors.tierHustler;
    }
  }

  IconData get _icon {
    switch (tier) {
      case 5:
        return Icons.diamond;
      case 4:
        return Icons.rocket_launch;
      case 3:
        return Icons.star;
      case 2:
        return Icons.star_border;
      default:
        return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Icon(
        _icon,
        size: size,
        color: _color,
      ),
    );
  }
}
