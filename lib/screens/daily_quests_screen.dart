import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../forui/v_hub_page.dart';
import '../state/quest_provider.dart';
import '../theme/v_colors.dart';
import '../theme/v_tokens.dart';
import '../widgets/core/empty_state.dart';

/// Lists today's daily quests (distinct from seasonal `/challenges`).
class DailyQuestsScreen extends ConsumerStatefulWidget {
  const DailyQuestsScreen({super.key});

  @override
  ConsumerState<DailyQuestsScreen> createState() => _DailyQuestsScreenState();
}

class _DailyQuestsScreenState extends ConsumerState<DailyQuestsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(questProvider.notifier).loadQuests();
    });
  }

  @override
  Widget build(BuildContext context) {
    final questState = ref.watch(questProvider);
    final quests = questState.quests;

    return VHubPage(
      title: 'Daily Quests',
      showBack: true,
      headerActions: [
        FHeaderAction(
          icon: const Icon(FIcons.rotateCw),
          onPress: () => ref.read(questProvider.notifier).loadQuests(),
        ),
      ],
      body: quests.isEmpty
          ? const AppEmptyState(
              title: 'Loading today\'s quests',
              description: 'If this stays empty, pull to refresh.',
              icon: Icons.flag_outlined,
            )
          : ListView.separated(
              padding: const EdgeInsets.all(VSpacing.md),
              itemCount: quests.length,
              separatorBuilder: (_, __) => const SizedBox(height: VSpacing.sm),
              itemBuilder: (context, index) {
                final q = quests[index];
                final progress = q.target > 0 ? q.progress / q.target : 0.0;
                return FCard(
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
                        LinearProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                        ),
                        const SizedBox(height: VSpacing.xs),
                        Text(
                          '${q.progress}/${q.target} · ${q.xpReward} XP',
                          style: theme.textTheme.bodySmall,
                        ),
                        if (q.isComplete && !q.claimed)
                          Padding(
                            padding: const EdgeInsets.only(top: VSpacing.sm),
                            child: FButton(
                              onPress: () async {
                                await ref
                                    .read(questProvider.notifier)
                                    .claimQuest(q.id);
                              },
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
