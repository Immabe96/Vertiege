import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../forui/v_hub_page.dart';
import '../../state/challenge_provider.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../../utils/haptics.dart';
import '../../ui/icons/v_icons.dart';
import '../../widgets/core/empty_state.dart';
import '../../widgets/core/screen_loading.dart';

class ChallengesScreen extends ConsumerStatefulWidget {
  const ChallengesScreen({super.key});

  @override
  ConsumerState<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends ConsumerState<ChallengesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(challengeProvider.notifier).loadChallengesForWorld('');
    });
  }

  @override
  Widget build(BuildContext context) {
    final challengeState = ref.watch(challengeProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return VHubPage(
      title: 'Seasonal Challenges',
      showBack: true,
      body: challengeState.isLoading
          ? const ScreenLoading.list()
          : challengeState.activeChallenges.isEmpty
              ? const AppEmptyState(
                  title: 'No active challenges',
                  description: 'Check back when a new season starts!',
                  icon: Icons.emoji_events_outlined,
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(VSpacing.md),
                  itemCount: challengeState.activeChallenges.length,
                  itemBuilder: (context, index) {
                    final challenge = challengeState.activeChallenges[index];
                    final progress =
                        challengeState.userProgress[challenge.id];
                    final isCompleted =
                        challengeState.completedChallengeIds.contains(
                          challenge.id,
                        );
                    return _ChallengeCard(
                      challenge: challenge,
                      progress: progress,
                      isCompleted: isCompleted,
                    );
                  },
                ),
    );
  }
}

class _ChallengeCard extends ConsumerWidget {
  final ChallengeData challenge;
  final ChallengeProgressData? progress;
  final bool isCompleted;

  const _ChallengeCard({
    required this.challenge,
    this.progress,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentValue = progress?.currentValue ?? 0;
    final targetValue = challenge.targetValue;
    final progressPercent = targetValue > 0
        ? (currentValue / targetValue).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: VSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? VColors.glassBackgroundDark : VColors.glassBackground,
        borderRadius: BorderRadius.circular(VRadius.lg),
        border: Border.all(
          color: isCompleted
              ? VColors.success.withValues(alpha: 0.3)
              : (isDark ? VColors.glassBorderDark : VColors.glassBorder),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(VSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(VSpacing.xs),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? VColors.success.withValues(alpha: 0.15)
                        : VColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(VRadius.md),
                  ),
                  child: Icon(
                    isCompleted
                        ? Icons.check_circle
                        : Icons.emoji_events_outlined,
                    size: VIconSize.md,
                    color: isCompleted ? VColors.success : VColors.primary,
                  ),
                ),
                const SizedBox(width: VSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        challenge.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: VFontWeight.semiBold,
                        ),
                      ),
                      Text(
                        challenge.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? VColors.onSurfaceVariantDark
                              : VColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: VSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(VRadius.pill),
              child: LinearProgressIndicator(
                value: progressPercent,
                minHeight: 8,
                backgroundColor: isDark
                    ? VColors.surfaceContainerHighDark
                    : VColors.surfaceContainerHigh,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isCompleted ? VColors.success : VColors.primary,
                ),
              ),
            ),
            const SizedBox(height: VSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$currentValue / $targetValue',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isDark
                        ? VColors.onSurfaceVariantDark
                        : VColors.onSurfaceVariant,
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      Icons.star,
                      size: VIconSize.xs,
                      color: VColors.secondary,
                    ),
                    const SizedBox(width: VSpacing.xxs),
                    Text(
                      '+${challenge.xpReward} XP',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: VColors.secondary,
                        fontWeight: VFontWeight.semiBold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (challenge.cosmeticReward != null) ...[
              const SizedBox(height: VSpacing.xs),
              Row(
                children: [
                  Icon(
                    Icons.palette,
                    size: VIconSize.xs,
                    color: VColors.tertiary,
                  ),
                  const SizedBox(width: VSpacing.xxs),
                  Text(
                    'Reward: ${challenge.cosmeticReward}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: VColors.tertiary,
                      fontWeight: VFontWeight.semiBold,
                    ),
                  ),
                ],
              ),
            ],
            if (isCompleted) ...[
              const SizedBox(height: VSpacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: isCompleted
                      ? () {
                          Haptics.light();
                          ref
                              .read(challengeProvider.notifier)
                              .claimReward(challenge.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Reward claimed!'),
                              backgroundColor: VColors.success,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  VRadius.md,
                                ),
                              ),
                            ),
                          );
                        }
                      : null,
                  icon: const Icon(VIcons.gavel, size: VIconSize.md),
                  label: const Text('Claim Reward'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
