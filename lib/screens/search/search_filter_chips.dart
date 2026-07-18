import 'package:flutter/material.dart';

import '../../theme/prestige_noir.dart';
import '../../theme/v_tokens.dart';
import 'prestige_filter_chip.dart';
import 'search_types.dart';

class SearchFilterChips extends StatelessWidget {
  final SearchMode mode;
  final SearchCategory category;
  final String query;
  final ValueChanged<SearchMode> onModeChanged;
  final ValueChanged<SearchCategory> onCategoryChanged;

  const SearchFilterChips({
    super.key,
    required this.mode,
    required this.category,
    required this.query,
    required this.onModeChanged,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: PrestigeNoir.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          VSpacing.md,
          VSpacing.sm,
          VSpacing.md,
          VSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  PrestigeFilterChip(
                    label: 'All',
                    selected: mode == SearchMode.all,
                    onTap: () => onModeChanged(SearchMode.all),
                  ),
                  const SizedBox(width: 6),
                  PrestigeFilterChip(
                    label: 'Following',
                    selected: mode == SearchMode.following,
                    onTap: () => onModeChanged(SearchMode.following),
                  ),
                  const SizedBox(width: 6),
                  PrestigeFilterChip(
                    label: 'Allies',
                    selected: mode == SearchMode.allies,
                    onTap: () => onModeChanged(SearchMode.allies),
                  ),
                ],
              ),
            ),
            if (query.length >= 2) ...[
              const SizedBox(height: VSpacing.sm),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    PrestigeFilterChip(
                      label: 'Everything',
                      selected: category == SearchCategory.all,
                      onTap: () => onCategoryChanged(SearchCategory.all),
                    ),
                    const SizedBox(width: 6),
                    PrestigeFilterChip(
                      label: 'Worlds',
                      selected: category == SearchCategory.worlds,
                      onTap: () => onCategoryChanged(SearchCategory.worlds),
                    ),
                    const SizedBox(width: 6),
                    PrestigeFilterChip(
                      label: 'Residents',
                      selected: category == SearchCategory.people,
                      onTap: () => onCategoryChanged(SearchCategory.people),
                    ),
                    const SizedBox(width: 6),
                    PrestigeFilterChip(
                      label: 'Posts',
                      selected: category == SearchCategory.posts,
                      onTap: () => onCategoryChanged(SearchCategory.posts),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
