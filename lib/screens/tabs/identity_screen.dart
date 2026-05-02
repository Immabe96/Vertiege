import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/achievement.dart';
import '../../models/resident.dart';
import '../../state/resident_provider.dart';
import '../../state/achievement_provider.dart';
import '../../theme/design_system.dart';
import '../../widgets/core/fade_in.dart';
import '../../widgets/profile/cosmetic_avatar.dart';
import '../../widgets/profile/name_banner.dart';
import '../../widgets/profile/badge_display.dart';
import '../../widgets/profile/share_card.dart';

class IdentityScreen extends ConsumerWidget {
  const IdentityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resident = ref.watch(residentProvider).resident;
    final achievements = ref.watch(achievementProvider);
    final theme = Theme.of(context);

    if (resident == null) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      appBar: AppBar(title: const Text('Identity')),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(residentProvider.notifier).loadResident();
          await ref.read(achievementProvider.notifier).loadAchievements();
          await Future<void>.delayed(const Duration(milliseconds: 200));
        },
        child: ListView(
          padding: const EdgeInsets.all(Spacing.md),
          children: [
            Center(
              child: Hero(
                tag: 'avatar-${resident.id}',
                child: CosmeticAvatar(
                  totalXp: achievements.totalXp,
                  size: 80,
                  imageUrl: resident.avatarUrl,
                ),
              ),
            ),
            const SizedBox(height: Spacing.md - 4),

            FadeIn(
              delayMs: 60,
              child: Center(child: NameBanner(profession: resident.profession, name: resident.name)),
            ),
            const SizedBox(height: 4),
            FadeIn(
              delayMs: 80,
              child: Center(child: Text(resident.tier.label, style: theme.textTheme.bodyLarge)),
            ),
            const SizedBox(height: 4),
            FadeIn(
              delayMs: 95,
              child: _ProfileStrength(resident: resident),
            ),
            const SizedBox(height: 4),
            FadeIn(
              delayMs: 100,
              child: Center(child: Text('${achievements.totalXp} XP', style: theme.textTheme.titleMedium)),
            ),
            if (resident.following.isNotEmpty) ...[
              const SizedBox(height: 4),
              FadeIn(
                delayMs: 110,
                child: Center(
                  child: Text('Following ${resident.following.length} resident${resident.following.length == 1 ? '' : 's'}',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
                ),
              ),
            ],
            const SizedBox(height: 16),
            FadeIn(delayMs: 120, child: BadgeDisplay(earnedBadgeIds: resident.decorations)),
            const SizedBox(height: 16),
            FadeIn(
              delayMs: 150,
              child: ListTile(
                leading: const Icon(Icons.emoji_events),
                title: const Text('Achievements'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/achievements'),
              ),
            ),
            FadeIn(
              delayMs: 170,
              child: ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Settings'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/settings'),
              ),
            ),
            const SizedBox(height: 16),
            FadeIn(
              delayMs: 200,
              child: ShareCard(
                resident: resident,
                totalXp: achievements.totalXp,
                achievementCount:
                    achievements.userAchievements.where((a) => a.status == AchievementStatus.verified).length,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileStrength extends StatelessWidget {
  final Resident resident;
  const _ProfileStrength({required this.resident});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final checks = [
      resident.name.isNotEmpty && resident.name != 'Traveler',
      resident.bio.isNotEmpty,
      resident.profession != null && resident.profession!.isNotEmpty,
      resident.avatarUrl.isNotEmpty && !resident.avatarUrl.contains('placeholder'),
      resident.decorations.isNotEmpty,
      resident.streakCount >= 3,
    ];
    final done = checks.where((c) => c).length;
    final pct = done / checks.length;

    if (pct >= 1.0) return const SizedBox.shrink();

    return Column(
      children: [
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome, size: 12, color: theme.colorScheme.primary),
            const SizedBox(width: 4),
            Text('Profile ${(pct * 100).round()}% complete',
                style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary)),
          ],
        ),
        const SizedBox(height: 4),
        Center(
          child: Container(
            width: 120,
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: theme.colorScheme.surfaceContainerHighest,
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: pct,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
