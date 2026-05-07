import 'package:flutter/material.dart';
import '../../theme/design_system.dart';
import 'badge.dart' as badge_widget;

class BadgeDisplay extends StatelessWidget {
  final List<String> earnedBadgeIds;

  const BadgeDisplay({super.key, this.earnedBadgeIds = const []});

  @override
  Widget build(BuildContext context) {
    if (earnedBadgeIds.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: Spacing.sm,
      runSpacing: Spacing.xs,
      children: earnedBadgeIds.map((id) => badge_widget.Badge(decorationId: id)).toList(),
    );
  }
}
