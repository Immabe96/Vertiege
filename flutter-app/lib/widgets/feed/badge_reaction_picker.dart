import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/achievements.dart' as ach_config;
import '../../models/achievement.dart';
import '../../state/achievement_provider.dart';
import '../../theme/v_tokens.dart';
import '../../widgets/achievements/achievement_category_meta.dart';
import '../../widgets/achievements/achievement_icon.dart';
import '../core/tab_aware_sheet.dart';

/// Reaction key stored on posts for earned-badge reactions.
String badgeReactionKey(String achievementId) => 'badge:$achievementId';

bool isBadgeReactionKey(String key) => key.startsWith('badge:');

String? achievementIdFromBadgeReaction(String key) =>
    isBadgeReactionKey(key) ? key.substring('badge:'.length) : null;

/// Picker of verified achievements the resident can react with on a post.
class BadgeReactionPickerSheet extends ConsumerWidget {
  final ValueChanged<String> onPick;

  const BadgeReactionPickerSheet({super.key, required this.onPick});

  static Future<void> show(
    BuildContext context, {
    required ValueChanged<String> reactionKey,
  }) {
    return showTabAwareModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => BadgeReactionPickerSheet(onPick: reactionKey),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(achievementProvider);
    final verified = state.userAchievements
        .where((ua) => ua.status == AchievementStatus.verified)
        .map((ua) => ach_config.achievementForId(ua.achievementId))
        .whereType<Achievement>()
        .toList();

    return Padding(
      padding: EdgeInsets.only(
        left: VSpacing.md,
        right: VSpacing.md,
        top: VSpacing.md,
        bottom: MediaQuery.paddingOf(context).bottom + VSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(VRadius.sm),
              ),
            ),
          ),
          const SizedBox(height: VSpacing.md),
          Text(
            'React with a badge',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: VFontWeight.semiBold,
            ),
          ),
          const SizedBox(height: VSpacing.sm),
          if (verified.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: VSpacing.lg),
              child: Text(
                'Earn and verify achievements to unlock badge reactions.',
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            )
          else
            SizedBox(
              height: 220,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: VSpacing.sm,
                  crossAxisSpacing: VSpacing.sm,
                ),
                itemCount: verified.length,
                itemBuilder: (context, index) {
                  final ach = verified[index];
                  final meta = metaForCategory(ach.category);
                  return Material(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(VRadius.md),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(VRadius.md),
                      onTap: () {
                        Navigator.pop(context);
                        onPick(badgeReactionKey(ach.id));
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(VSpacing.xs),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AchievementBadgeAvatar(
                              achievement: ach,
                              accentColor: meta.color,
                              size: VBadgeSize.avatarCompact,
                              showEarnedBadge: true,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              ach.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
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
