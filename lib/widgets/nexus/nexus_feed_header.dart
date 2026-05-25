import 'package:flutter/material.dart';

import '../../theme/v_context_colors.dart';
import '../../theme/v_tokens.dart';
import 'feed_sort_dropdown.dart';
import 'feed_tab_chip.dart';

/// Pinned feed filter row (tabs + sort) on Nexus.
class NexusFeedHeader extends StatelessWidget {
  final bool isDark;
  final bool allSelected;
  final bool followingSelected;
  final bool announcementsSelected;
  final FeedSort currentSort;
  final ValueChanged<FeedSort> onSortChanged;
  final VoidCallback onAllTap;
  final VoidCallback onFollowingTap;
  final VoidCallback onAnnouncementsTap;

  const NexusFeedHeader({
    super.key,
    required this.isDark,
    required this.allSelected,
    required this.followingSelected,
    required this.announcementsSelected,
    required this.currentSort,
    required this.onSortChanged,
    required this.onAllTap,
    required this.onFollowingTap,
    required this.onAnnouncementsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDark ? context.vSurface : context.vSurface,
      padding: const EdgeInsets.fromLTRB(
        VSpacing.md,
        VSpacing.xs,
        VSpacing.md,
        VSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FeedTabChip(
                    label: 'All',
                    selected: allSelected,
                    onTap: onAllTap,
                  ),
                  const SizedBox(width: 6),
                  FeedTabChip(
                    label: 'Following',
                    selected: followingSelected,
                    onTap: onFollowingTap,
                  ),
                  const SizedBox(width: 6),
                  FeedTabChip(
                    label: 'Announcements',
                    selected: announcementsSelected,
                    icon: Icons.campaign,
                    onTap: onAnnouncementsTap,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: VSpacing.sm),
          FeedSortDropdown(
            currentSort: currentSort,
            onChanged: onSortChanged,
          ),
        ],
      ),
    );
  }
}

class NexusFeedHeaderDelegate extends SliverPersistentHeaderDelegate {
  final NexusFeedHeader header;

  NexusFeedHeaderDelegate({required this.header});

  static const double height = 52;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return header;
  }

  @override
  bool shouldRebuild(covariant NexusFeedHeaderDelegate oldDelegate) =>
      oldDelegate.header.isDark != header.isDark ||
      oldDelegate.header.allSelected != header.allSelected ||
      oldDelegate.header.followingSelected != header.followingSelected ||
      oldDelegate.header.announcementsSelected != header.announcementsSelected ||
      oldDelegate.header.currentSort != header.currentSort;
}
