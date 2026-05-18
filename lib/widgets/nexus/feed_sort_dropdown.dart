import 'package:flutter/material.dart';
import '../../theme/v_colors.dart';
import '../../theme/design_system.dart';
import '../../ui/icons/v_icons.dart';

enum FeedSort { latest, hot, top }

class FeedSortDropdown extends StatelessWidget {
  final FeedSort currentSort;
  final ValueChanged<FeedSort> onChanged;

  const FeedSortDropdown({
    super.key,
    required this.currentSort,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final label = switch (currentSort) {
      FeedSort.latest => 'Latest',
      FeedSort.hot => 'Hot',
      FeedSort.top => 'Top',
    };

    final mutedColor = isDark ? VColors.onSurfaceVariantDark : VColors.onSurfaceVariant;

    return PopupMenuButton<FeedSort>(
      initialValue: currentSort,
      onSelected: onChanged,
      offset: const Offset(0, 36),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RadiusTokens.card),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(VRadius.xl),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sort, size: 14, color: mutedColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: mutedColor,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: mutedColor,
            ),
          ],
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: FeedSort.latest,
          child: Row(
            children: [
              Icon(
                Icons.access_time,
                size: IconSizes.sm,
                color: currentSort == FeedSort.latest
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
              ),
              const SizedBox(width: Spacing.sm),
              const Text('Latest'),
            ],
          ),
        ),
        PopupMenuItem(
          value: FeedSort.hot,
          child: Row(
            children: [
              Icon(
                Icons.local_fire_department,
                size: IconSizes.sm,
                color: currentSort == FeedSort.hot
                    ? VColors.warning
                    : theme.colorScheme.outline,
              ),
              const SizedBox(width: Spacing.sm),
              const Text('Hot'),
            ],
          ),
        ),
        PopupMenuItem(
          value: FeedSort.top,
          child: Row(
            children: [
              Icon(
                Icons.trending_up,
                size: IconSizes.sm,
                color: currentSort == FeedSort.top
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
              ),
              const SizedBox(width: Spacing.sm),
              const Text('Top'),
            ],
          ),
        ),
      ],
    );
  }
}
