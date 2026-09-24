import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/achievements.dart' as ach_config;
import '../../models/achievement.dart';
import '../../state/achievement_provider.dart';
import '../../theme/v_commune_colors.dart';
import '../../theme/v_tokens.dart';
import '../achievements/achievement_category_meta.dart';
import '../achievements/achievement_icon.dart';
import '../core/v_feedback.dart';
import '../../utils/haptics.dart';

/// Pick a verified achievement to embed in chat (channels or DMs).
Future<Achievement?> pickVerifiedAchievementToShare(
  BuildContext context,
  WidgetRef ref,
) async {
  Haptics.light();
  final verified = ref
      .read(achievementProvider)
      .userAchievements
      .where((ua) => ua.status == AchievementStatus.verified)
      .map((ua) => ach_config.achievementForId(ua.achievementId))
      .whereType<Achievement>()
      .toList();

  if (verified.isEmpty) {
    VFeedback.showMessage(
      context,
      'Earn and verify achievements to share them in chat.',
    );
    return null;
  }

  return showModalBottomSheet<Achievement>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(VRadius.xl)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(VSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Share achievement',
              style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                fontWeight: VFontWeight.bold,
                color: VCommuneColors.headerPrimaryOf(
                  Theme.of(ctx).brightness,
                ),
              ),
            ),
            const SizedBox(height: VSpacing.sm),
            SizedBox(
              height: 220,
              child: ListView.separated(
                itemCount: verified.length,
                separatorBuilder: (_, _) => const SizedBox(height: VSpacing.xs),
                itemBuilder: (_, i) {
                  final ach = verified[i];
                  final meta = metaForCategory(ach.category);
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.pop(ctx, ach),
                      borderRadius: BorderRadius.circular(VRadius.md),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: VSpacing.sm,
                          vertical: VSpacing.sm,
                        ),
                        child: Row(
                          children: [
                            AchievementBadgeAvatar(
                              achievement: ach,
                              accentColor: meta.color,
                              size: VBadgeSize.avatarCompact,
                            ),
                            const SizedBox(width: VSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(ach.title),
                                  Text('${ach.xpValue} XP'),
                                ],
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
      ),
    ),
  );
}
