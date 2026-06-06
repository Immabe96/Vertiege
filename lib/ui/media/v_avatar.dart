import 'package:flutter/material.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../../utils/tier_utils.dart';
import '../../widgets/core/status_dot.dart';
import '../../widgets/shared/tier_icon.dart';

class VAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? fallbackSeed;
  final double size;
  final VoidCallback? onTap;
  final Presence? presence;
  /// Resident tier (1–5) — renders a colored ring (DCX-107).
  final int? tier;

  const VAvatar({
    super.key,
    this.imageUrl,
    this.fallbackSeed,
    this.size = 40,
    this.onTap,
    this.presence,
    this.tier,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final fallbackColor = _seedColor(fallbackSeed ?? '', isDark);

    Widget avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: fallbackColor, shape: BoxShape.circle),
      child: Center(
        child: Text(
          _initials(fallbackSeed),
          style: TextStyle(
            color: VColors.onPrimary,
            fontSize: size * 0.35,
            fontWeight: VFontWeight.semiBold,
          ),
        ),
      ),
    );

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      avatar = Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(shape: BoxShape.circle),
        child: ClipOval(
          child: Image.network(
            imageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => avatar,
          ),
        ),
      );
    }

    Widget result = avatar;
    if (tier != null && tier! >= 1) {
      final ringColor = tierStandingColor(tier!);
      final ringWidth = (size * 0.06).clamp(2.0, 4.0);
      result = Container(
        width: size + ringWidth * 2,
        height: size + ringWidth * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: ringColor, width: ringWidth),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            avatar,
            Positioned(
              right: -2,
              bottom: -2,
              child: TierIcon(tier: tier!, size: (size * 0.32).clamp(14, 20)),
            ),
          ],
        ),
      );
    }

    if (presence != null) {
      result = Stack(
        clipBehavior: Clip.none,
        children: [
          result,
          Positioned(
            right: 0,
            bottom: 0,
            child: StatusDot(
              presence: presence!,
              size: (size * 0.28).clamp(8, 14),
              borderWidth: 1.5,
            ),
          ),
        ],
      );
    }

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: result);
    }

    return result;
  }

  Color _seedColor(String seed, bool isDark) {
    if (seed.isEmpty) return isDark ? VColors.primaryLight : VColors.primary;
    final hash = seed.hashCode.abs();
    final colors = [
      VColors.primary,
      VColors.secondary,
      VColors.tertiary,
      VColors.success,
      VColors.tierHighRoller,
      VColors.tierHustler,
      VColors.tierElite,
      VColors.tierOldMoney,
    ];
    return colors[hash % colors.length];
  }

  String _initials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
}
