import 'package:flutter/material.dart';
import '../../theme/v_tokens.dart';
import 'badge.dart' as badge_widget;

class BadgeDisplay extends StatelessWidget {
  final List<String> earnedBadgeIds;

  const BadgeDisplay({super.key, this.earnedBadgeIds = const []});

  @override
  Widget build(BuildContext context) {
    if (earnedBadgeIds.isEmpty) return const SizedBox.shrink();

    final uniqueProfessionBadges = earnedBadgeIds.toSet().toList();

    return Wrap(
      spacing: VSpacing.sm,
      runSpacing: VSpacing.xs,
      children: uniqueProfessionBadges
          .map((id) => badge_widget.Badge(decorationId: id))
          .toList(),
    );
  }
}
