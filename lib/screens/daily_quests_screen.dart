import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:vertiege/ui/ui.dart';
import '../services/analytics_events.dart';
import '../services/analytics_service.dart';
import '../state/quest_provider.dart';
import '../state/resident_provider.dart';
import '../theme/prestige_noir.dart';
import '../theme/v_colors.dart';
import '../theme/v_tokens.dart';
import '../widgets/core/empty_state.dart';
import '../widgets/core/screen_loading.dart';
import '../widgets/progression/prestige_noir_ui.dart';

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
      unawaited(AnalyticsService.logEvent(AnalyticsEvents.streakShieldUsed));
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
    final questState = ref.watch(questProvider);
    final quests = questState.quests;
    final resident = ref.watch(residentProvider).resident;
    final shields = resident?.streakShields ?? 0;
    final streak = resident?.streakCount ?? 0;

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            VSpacing.lg,
            VSpacing.lg,
            VSpacing.lg,
            0,
          ),
          child: PrestigeStreakBanner(
            streak: streak,
            nextMilestone: prestigeNextStreakMilestone(streak),
          ),
        ),
        if (shields > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              VSpacing.lg,
              VSpacing.md,
              VSpacing.lg,
              0,
            ),
            child: VPrestigeCard(
              padding: const EdgeInsets.all(VSpacing.lg),
              child: Row(
                children: [
                  const Icon(
                    Icons.shield,
                    color: VColors.brand,
                    size: VIconSize.lg,
                  ),
                  const SizedBox(width: VSpacing.sm),
                  Expanded(
                    child: Text(
                      shields == 1
                          ? '1 streak shield — covers one missed day'
                          : '$shields streak shields — each covers one missed day',
                      style: const TextStyle(
                        fontSize: VFontSize.labelMd,
                        color: PrestigeNoir.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        Expanded(
          child: questState.isLoading && quests.isEmpty
              ? const ScreenLoading.list()
              : quests.isEmpty
              ? AppEmptyState(
                  title: 'No quests today',
                  description:
                      'Daily quests will appear here. Pull to refresh if this looks wrong.',
                  icon: Icons.flag_outlined,
                  actionLabel: 'Refresh',
                  onAction: () =>
                      ref.read(questProvider.notifier).loadQuests(),
                )
              : RefreshIndicator(
                  onRefresh: () =>
                      ref.read(questProvider.notifier).loadQuests(),
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(VSpacing.lg),
                    itemCount: quests.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: VSpacing.sm),
                    itemBuilder: (context, index) {
                      final q = quests[index];
                      return _QuestCard(
                        quest: q,
                        onClaim: () => ref
                            .read(questProvider.notifier)
                            .claimQuest(q.id),
                      );
                    },
                  ),
                ),
        ),
      ],
    );

    if (widget.embedInHub) return body;

    return VHubPage(
      title: 'Daily Quests',
      showBack: true,
      headerActions: [
        VHeaderAction(
          icon: const Icon(VIcons.rotateCw),
          onPress: () => ref.read(questProvider.notifier).loadQuests(),
        ),
      ],
      body: body,
    );
  }
}

class _QuestCard extends StatelessWidget {
  final Quest quest;
  final VoidCallback onClaim;

  const _QuestCard({required this.quest, required this.onClaim});

  @override
  Widget build(BuildContext context) {
    final progress = quest.target > 0 ? quest.progress / quest.target : 0.0;
    final completed = quest.isComplete;
    final claimed = quest.claimed;
    final fillColor = claimed || completed
        ? VColors.success
        : progress > 0.5
        ? VColors.brand
        : VColors.warning;

    return VPrestigeCard(
      padding: const EdgeInsets.all(VSpacing.lg),
      borderColor: completed
          ? VColors.success.withValues(alpha: 0.5)
          : PrestigeNoir.borderLight,
      backgroundColor: completed
          ? Color.alphaBlend(
              VColors.success.withValues(alpha: 0.06),
              PrestigeNoir.surfaceRaised,
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 40,
                child: Icon(
                  prestigeQuestIcon(quest.icon),
                  size: 28,
                  color: completed ? VColors.success : PrestigeNoir.foreground,
                ),
              ),
              const SizedBox(width: VSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quest.label,
                      style: const TextStyle(
                        fontSize: VFontSize.bodyLg,
                        fontWeight: VFontWeight.bold,
                        color: PrestigeNoir.foreground,
                        letterSpacing: -0.01 * VFontSize.bodyLg,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _questDescription(quest.id),
                      style: const TextStyle(
                        fontSize: VFontSize.labelMd,
                        color: PrestigeNoir.muted,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: VSpacing.sm),
                    Row(
                      children: [
                        Text(
                          '+${quest.xpReward} XP',
                          style: const TextStyle(
                            fontSize: VFontSize.bodyMd,
                            fontWeight: VFontWeight.bold,
                            color: VColors.brand,
                          ),
                        ),
                        const SizedBox(width: VSpacing.sm),
                        Expanded(
                          child: PrestigeXpBar(
                            value: progress,
                            fillColor: fillColor,
                          ),
                        ),
                        const SizedBox(width: VSpacing.sm),
                        if (claimed)
                          const Text(
                            'Claimed',
                            style: TextStyle(
                              fontSize: VFontSize.labelSm,
                              fontWeight: VFontWeight.semiBold,
                              color: VColors.success,
                            ),
                          )
                        else if (completed)
                          _ClaimChip(onClaim: onClaim)
                        else
                          Text(
                            '${quest.progress}/${quest.target}',
                            style: const TextStyle(
                              fontSize: VFontSize.labelSm,
                              color: PrestigeNoir.muted,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _questDescription(String id) => switch (id) {
    'post_quest' => 'Share something in any world channel',
    'react_quest' => 'Like or react to Nexus feed posts',
    'comment_quest' => 'Join the conversation on a post',
    'explore_quest' => 'Explore worlds outside your home',
    _ => 'Complete this daily objective',
  };
}

class _ClaimChip extends StatelessWidget {
  final VoidCallback onClaim;

  const _ClaimChip({required this.onClaim});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: VColors.brand,
      borderRadius: BorderRadius.circular(VRadius.sm),
      child: InkWell(
        onTap: onClaim,
        borderRadius: BorderRadius.circular(VRadius.sm),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Text(
            'Claim',
            style: TextStyle(
              fontSize: VFontSize.labelMd,
              fontWeight: VFontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}
