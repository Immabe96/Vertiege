import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/quest_provider.dart';
import '../theme/v_colors.dart';
import '../theme/v_tokens.dart';

/// Lists today's daily quests (distinct from seasonal `/challenges`).
class DailyQuestsScreen extends ConsumerWidget {
  const DailyQuestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final questState = ref.watch(questProvider);
    final quests = questState.quests;

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Quests')),
      body: quests.isEmpty
          ? Center(
              child: Text(
                'No quests for today yet.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: VColors.onSurfaceVariant,
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(VSpacing.md),
              itemCount: quests.length,
              separatorBuilder: (_, __) => const SizedBox(height: VSpacing.sm),
              itemBuilder: (context, index) {
                final q = quests[index];
                final progress = q.target > 0 ? q.progress / q.target : 0.0;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(VSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          q.label,
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: VSpacing.xs),
                        LinearProgressIndicator(value: progress.clamp(0.0, 1.0)),
                        const SizedBox(height: VSpacing.xs),
                        Text(
                          '${q.progress}/${q.target} · ${q.xpReward} XP',
                          style: theme.textTheme.bodySmall,
                        ),
                        if (q.isComplete && !q.claimed)
                          Padding(
                            padding: const EdgeInsets.only(top: VSpacing.sm),
                            child: FilledButton(
                              onPressed: () => ref
                                  .read(questProvider.notifier)
                                  .claimQuest(q.id),
                              child: const Text('Claim reward'),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
