import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vertiege/ui/ui.dart';

import '../../config/achievements.dart';
import 'package:vertiege/ui/ui.dart';
import '../../models/achievement.dart';
import '../../state/achievement_provider.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../../widgets/achievements/achievement_category_meta.dart';
import '../../widgets/achievements/achievement_list_tile.dart';
import '../../widgets/achievements/achievement_proof_sheet.dart';
import '../../widgets/core/empty_state.dart';

enum _AchievementFilter { all, verified, pending, rejected, available }

class AchievementCategoryScreen extends ConsumerStatefulWidget {
  final String category;

  const AchievementCategoryScreen({super.key, required this.category});

  @override
  ConsumerState<AchievementCategoryScreen> createState() =>
      _AchievementCategoryScreenState();
}

class _AchievementCategoryScreenState
    extends ConsumerState<AchievementCategoryScreen> {
  _AchievementFilter _filter = _AchievementFilter.all;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final cat = AchievementCategory.values
        .where((c) => c.name == widget.category)
        .firstOrNull;
    if (cat == null) {
      return VHubPage(
        title: 'Achievements',
        showBack: true,
        body: const AppEmptyState(
          title: 'Category not found',
          description: 'This achievement category is no longer available.',
          icon: Icons.emoji_events_outlined,
          variant: EmptyStateVariant.error,
        ),
      );
    }

    final meta = metaForCategory(cat);
    final achievementState = ref.watch(achievementProvider);
    final notifier = ref.read(achievementProvider.notifier);
    final progress = notifier.getCategoryProgress(cat.name);

    final allInCategory = achievements.where((a) => a.category == cat).toList();

    final query = _searchQuery.trim().toLowerCase();
    final filtered = allInCategory.where((achievement) {
      if (query.isNotEmpty) {
        final haystack =
            '${achievement.title} ${achievement.description} ${achievement.id}'
                .toLowerCase();
        if (!haystack.contains(query)) return false;
      }
      final status = notifier.getAchievementStatus(achievement.id);
      return switch (_filter) {
        _AchievementFilter.all => true,
        _AchievementFilter.verified => status == AchievementStatus.verified,
        _AchievementFilter.pending => status == AchievementStatus.submitted,
        _AchievementFilter.rejected => status == AchievementStatus.rejected,
        _AchievementFilter.available => status == AchievementStatus.locked,
      };
    }).toList();

    return VHubPage(
      title: meta.label,
      showBack: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              VSpacing.md,
              VSpacing.sm,
              VSpacing.md,
              0,
            ),
            child: VSurfaceCard(
                child: Text(
                  '${progress.earned} verified · ${progress.total - progress.earned} remaining · ${progress.xp} XP in this category',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? VColors.onSurfaceVariantDark
                        : VColors.onSurfaceVariant,
                  ),
                ),
            ),
          ),
          if (allInCategory.length > 12) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                VSpacing.md,
                VSpacing.sm,
                VSpacing.md,
                0,
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search ${meta.label.toLowerCase()} achievements',
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(VRadius.md),
                  ),
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
            ),
            const SizedBox(height: VSpacing.sm),
          ],
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: VSpacing.md),
            child: Row(
              children: _AchievementFilter.values.map((f) {
                final selected = _filter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: VSpacing.sm),
                  child: FilterChip(
                    label: Text(_filterLabel(f)),
                    selected: selected,
                    onSelected: (_) => setState(() => _filter = f),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: VSpacing.sm),
          Expanded(
            child: filtered.isEmpty
                ? AppEmptyState(
                    title: 'No achievements here',
                    description: _emptyMessage(_filter),
                    icon: Icons.emoji_events_outlined,
                    variant: EmptyStateVariant.default_,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      VSpacing.md,
                      0,
                      VSpacing.md,
                      VSpacing.xxl,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final achievement = filtered[index];
                      final status = notifier.getAchievementStatus(
                        achievement.id,
                      );
                      final userAch = achievementState.userAchievements
                          .where((a) => a.achievementId == achievement.id)
                          .firstOrNull;
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index < filtered.length - 1 ? VSpacing.xs : 0,
                        ),
                        child: AchievementListTile(
                          achievement: achievement,
                          status: status,
                          proofUri: userAch?.proofUri,
                          aiNotes: userAch?.aiNotes,
                          isInApp:
                              achievement.category == AchievementCategory.inApp,
                          onPress: () => showAchievementProofSheet(
                            context: context,
                            ref: ref,
                            achievement: achievement,
                            status: status,
                            userAchievement: userAch,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  static String _filterLabel(_AchievementFilter f) {
    return switch (f) {
      _AchievementFilter.all => 'All',
      _AchievementFilter.verified => 'Verified',
      _AchievementFilter.pending => 'Pending',
      _AchievementFilter.rejected => 'Rejected',
      _AchievementFilter.available => 'Available',
    };
  }

  static String _emptyMessage(_AchievementFilter f) {
    return switch (f) {
      _AchievementFilter.all => 'Nothing in this category yet.',
      _AchievementFilter.verified =>
        'You have not verified any achievements in this category.',
      _AchievementFilter.pending => 'No submissions awaiting review.',
      _AchievementFilter.rejected =>
        'No rejected submissions in this category.',
      _AchievementFilter.available =>
        'You have submitted everything available here.',
    };
  }
}
