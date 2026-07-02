import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/achievement.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';

/// Compact status for pending / rejected achievements on Identity.
class AchievementQueueSummary extends StatelessWidget {
  final List<UserAchievement> userAchievements;

  const AchievementQueueSummary({super.key, required this.userAchievements});

  @override
  Widget build(BuildContext context) {
    final pending = userAchievements
        .where((a) => a.status == AchievementStatus.submitted)
        .length;
    final rejected = userAchievements
        .where((a) => a.status == AchievementStatus.rejected)
        .length;

    if (pending == 0 && rejected == 0) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(VSpacing.lg, 0, VSpacing.lg, VSpacing.sm),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/achievements'),
          borderRadius: BorderRadius.circular(VRadius.lg),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(VSpacing.md),
            decoration: BoxDecoration(
              color: VColors.surfaceContainerDark,
              borderRadius: BorderRadius.circular(VRadius.lg),
              border: Border.all(
                color: rejected > 0
                    ? VColors.error.withValues(alpha: 0.35)
                    : VColors.warning.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  rejected > 0 ? Icons.refresh : Icons.hourglass_top,
                  color: rejected > 0 ? VColors.error : VColors.warning,
                ),
                const SizedBox(width: VSpacing.sm),
                Expanded(
                  child: Text(
                    _message(pending, rejected),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: VFontWeight.semiBold,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  size: VIconSize.md,
                  color: VColors.onSurfaceVariantDark,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _message(int pending, int rejected) {
    if (pending > 0 && rejected > 0) {
      return '$pending in review · $rejected need resubmit';
    }
    if (rejected > 0) {
      return rejected == 1
          ? '1 achievement needs resubmit'
          : '$rejected achievements need resubmit';
    }
    return pending == 1
        ? '1 achievement awaiting review'
        : '$pending achievements awaiting review';
  }
}
