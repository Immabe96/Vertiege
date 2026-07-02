import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/achievements.dart';
import '../../models/achievement.dart';
import '../../state/achievement_provider.dart';
import '../../theme/v_tokens.dart';
import '../../ui/overlays/v_sheet.dart';
import '../../widgets/achievements/achievement_category_meta.dart';
import '../../widgets/achievements/achievement_list_tile.dart';
import '../../widgets/achievements/achievement_proof_sheet.dart';
import '../../widgets/core/empty_state.dart';

/// Opens achievement category list in a hub sheet (DCX-124).
void showAchievementCategorySheet(
  BuildContext context, {
  required AchievementCategory category,
}) {
  showVSheet(
    context,
    AchievementCategorySheetBody(category: category),
    maxSize: 0.92,
  );
}

class AchievementCategorySheetBody extends ConsumerStatefulWidget {
  final AchievementCategory category;

  const AchievementCategorySheetBody({super.key, required this.category});

  @override
  ConsumerState<AchievementCategorySheetBody> createState() =>
      _AchievementCategorySheetBodyState();
}

class _AchievementCategorySheetBodyState
    extends ConsumerState<AchievementCategorySheetBody> {
  @override
  Widget build(BuildContext context) {
    final meta = metaForCategory(widget.category);
    final achievementState = ref.watch(achievementProvider);
    final notifier = ref.read(achievementProvider.notifier);
    final progress = notifier.getCategoryProgress(widget.category.name);
    final theme = Theme.of(context);

    final allInCategory =
        achievements.where((a) => a.category == widget.category).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        VSpacing.lg,
        VSpacing.sm,
        VSpacing.lg,
        VSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            meta.label,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: VFontWeight.bold,
            ),
          ),
          const SizedBox(height: VSpacing.xs),
          Text(
            '${progress.earned} verified · ${progress.total - progress.earned} remaining',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: VSpacing.md),
          if (allInCategory.isEmpty)
            const AppEmptyState(
              title: 'No achievements here',
              description: 'Nothing in this category yet.',
              icon: Icons.emoji_events_outlined,
              illustration: EmptyStateIllustration.achievements,
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: allInCategory.length,
                itemBuilder: (context, index) {
                  final achievement = allInCategory[index];
                  final status =
                      notifier.getAchievementStatus(achievement.id);
                  final userAch = achievementState.userAchievements
                      .where((a) => a.achievementId == achievement.id)
                      .firstOrNull;
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom:
                          index < allInCategory.length - 1 ? VSpacing.xs : 0,
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
}
