import 'package:flutter/material.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';

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

    final label = switch (currentSort) {
      FeedSort.latest => 'Latest',
      FeedSort.hot => 'Hot',
      FeedSort.top => 'Top',
    };

    const mutedColor = VColors.onSurfaceVariantDark;

    return PopupMenuButton<FeedSort>(
      initialValue: currentSort,
      onSelected: onChanged,
      offset: const Offset(0, 36),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(VRadius.lg),
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
            const Icon(Icons.sort, size: VIconSize.denseSm, color: mutedColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: mutedColor,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(
              Icons.arrow_drop_down,
              size: VIconSize.sm,
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
                size: VIconSize.sm,
                color: currentSort == FeedSort.latest
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
              ),
              const SizedBox(width: VSpacing.sm),
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
                size: VIconSize.sm,
                color: currentSort == FeedSort.hot
                    ? VColors.warning
                    : theme.colorScheme.outline,
              ),
              const SizedBox(width: VSpacing.sm),
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
                size: VIconSize.sm,
                color: currentSort == FeedSort.top
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
              ),
              const SizedBox(width: VSpacing.sm),
              const Text('Top'),
            ],
          ),
        ),
      ],
    );
  }
}
