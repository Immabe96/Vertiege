import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../state/quest_provider.dart';
import '../../../theme/v_colors.dart';
import '../../../theme/v_tokens.dart';

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
              const Icon(
                Icons.explore,
                size: VIconSize.md,
                color: VColors.tertiary,
              ),
              const SizedBox(width: VSpacing.xs),
              const Text(
                'DAILY QUESTS',
                style: TextStyle(
                  fontSize: VFontSize.labelSm,
                  fontWeight: VFontWeight.semiBold,
                  color: VColors.onSurfaceVariant,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: VSpacing.md),
          const Text(
            'No active quests',
            style: TextStyle(
              fontSize: VFontSize.bodyMd,
              color: VColors.outline,
            ),
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
            const Icon(
              Icons.explore,
              size: VIconSize.md,
              color: VColors.tertiary,
            ),
            const SizedBox(width: VSpacing.xs),
            const Expanded(
              child: Text(
                'DAILY QUESTS',
                style: TextStyle(
                  fontSize: VFontSize.labelSm,
                  fontWeight: VFontWeight.semiBold,
                  color: VColors.onSurfaceVariant,
                  letterSpacing: 0,
                ),
              ),
            ),
            Text(
              '$completed/$total',
              style: const TextStyle(
                fontSize: VFontSize.headlineMd,
                fontWeight: VFontWeight.bold,
                color: VColors.tertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: VSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(VRadius.sm),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 4,
            backgroundColor: VColors.glassBorder,
            valueColor: const AlwaysStoppedAnimation<Color>(VColors.tertiary),
          ),
        ),
        const SizedBox(height: VSpacing.sm),
        Text(
          '${quests.where((q) => q.isComplete && !q.claimed).length} ready to claim',
          style: const TextStyle(
            fontSize: VFontSize.labelSm,
            color: VColors.outline,
          ),
        ),
      ],
    );
  }
}
