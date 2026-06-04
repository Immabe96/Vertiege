import 'dart:async';

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../forui/v_hub_page.dart';
import '../services/analytics_events.dart';
import '../services/analytics_service.dart';
import '../state/quest_provider.dart';
import '../state/resident_provider.dart';
import '../theme/v_colors.dart';
import '../theme/v_tokens.dart';
import '../widgets/core/empty_state.dart';
import '../widgets/core/v_feedback.dart';

/// Lists today's daily quests (distinct from seasonal `/challenges`).
class DailyQuestsScreen extends ConsumerStatefulWidget {
  final bool embedInHub;

  const DailyQuestsScreen({super.key, this.embedInHub = false});

  @override
  ConsumerState<DailyQuestsScreen> createState() => _DailyQuestsScreenState();
}

class _DailyQuestsScreenState extends ConsumerState<DailyQuestsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(questProvider.notifier).loadQuests();
      unawaited(_tryStreakCheckIn());
    });
  }

  Future<void> _tryStreakCheckIn() async {
    final result = await ref.read(residentProvider.notifier).checkInToday();
    if (!mounted || result == null) return;
    if (result.shieldUsed) {
      unawaited(
        AnalyticsService.logEvent(AnalyticsEvents.streakShieldUsed),
      );
      VFeedback.showMessage(
        context,
        'Streak shield used — your streak continues.',
      );
    } else if (result.bonusXp > 0) {
      VFeedback.showMessage(
        context,
        'Day ${result.streak} streak · +${result.bonusXp} XP',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final questState = ref.watch(questProvider);
    final quests = questState.quests;
    final resident = ref.watch(residentProvider).resident;
    final shields = resident?.streakShields ?? 0;

    final body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (shields > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                VSpacing.md,
                VSpacing.md,
                VSpacing.md,
                0,
              ),
              child: FCard(
                child: Padding(
                  padding: const EdgeInsets.all(VSpacing.md),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.shield,
                        color: VColors.primary,
                        size: VIconSize.lg,
                      ),
                      const SizedBox(width: VSpacing.sm),
                      Expanded(
                        child: Text(
                          shields == 1
                              ? '1 streak shield — covers one missed day'
                              : '$shields streak shields — each covers one missed day',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(
            child: quests.isEmpty
                ? const AppEmptyState(
                    title: 'Loading today\'s quests',
                    description: 'If this stays empty, pull to refresh.',
                    icon: Icons.flag_outlined,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(VSpacing.md),
                    itemCount: quests.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: VSpacing.sm),
                    itemBuilder: (context, index) {
                      final q = quests[index];
                      final progress =
                          q.target > 0 ? q.progress / q.target : 0.0;
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
                                  padding: const EdgeInsets.only(
                                    top: VSpacing.sm,
                                  ),
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
          ),
        ],
      );

    if (widget.embedInHub) return body;

    return VHubPage(
      title: 'Daily Quests',
      showBack: true,
      headerActions: [
        FHeaderAction(
          icon: const Icon(FIcons.rotateCw),
          onPress: () => ref.read(questProvider.notifier).loadQuests(),
        ),
      ],
      body: body,
    );
  }
}
