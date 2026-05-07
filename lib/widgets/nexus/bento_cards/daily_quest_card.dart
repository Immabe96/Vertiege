import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../state/quest_provider.dart';
import '../../../theme/colors.dart';
import '../../../theme/design_system.dart';

/// Small card showing active quest progress.
class DailyQuestCard extends ConsumerWidget {
  const DailyQuestCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questState = ref.watch(questProvider);
    final quests = questState.quests;

    if (quests.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.explore, size: IconSizes.md, color: AppColors.tertiary),
              const SizedBox(width: Spacing.xs),
              const Text(
                'DAILY QUESTS',
                style: TextStyle(
                  fontSize: FontSizes.labelSm,
                  fontWeight: FontWeights.semiBold,
                  color: AppColors.inkSecondary,
                  letterSpacing: LetterSpacing.label,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),
          const Text(
            'No active quests',
            style: TextStyle(fontSize: FontSizes.bodyMd, color: AppColors.inkMuted),
          ),
        ],
      );
    }

    final completed = questState.completedCount;
    final total = quests.length;
    final progress = total > 0 ? completed / total : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Icon(Icons.explore, size: IconSizes.md, color: AppColors.tertiary),
            const SizedBox(width: Spacing.xs),
            const Expanded(
              child: Text(
                'DAILY QUESTS',
                style: TextStyle(
                  fontSize: FontSizes.labelSm,
                  fontWeight: FontWeights.semiBold,
                  color: AppColors.inkSecondary,
                  letterSpacing: LetterSpacing.label,
                ),
              ),
            ),
            Text(
              '$completed/$total',
              style: const TextStyle(
                fontSize: FontSizes.headlineMd,
                fontWeight: FontWeights.bold,
                color: AppColors.tertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 4,
            backgroundColor: AppColors.glassBorder,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.tertiary),
          ),
        ),
        const SizedBox(height: Spacing.sm),
        Text(
          '${quests.where((q) => q.isComplete && !q.claimed).length} ready to claim',
          style: const TextStyle(fontSize: FontSizes.labelSm, color: AppColors.inkMuted),
        ),
      ],
    );
  }
}
