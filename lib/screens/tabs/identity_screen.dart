import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/achievement.dart';
import '../../state/resident_provider.dart';
import '../../state/achievement_provider.dart';
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: CosmeticAvatar(
              totalXp: achievements.totalXp,
              size: 80,
              imageUrl: resident.avatarUrl,
            ),
          ),
          const SizedBox(height: 12),
          Center(child: NameBanner(profession: resident.profession, name: resident.name)),
          const SizedBox(height: 4),
          Center(child: Text(resident.tier.label, style: theme.textTheme.bodyLarge)),
          const SizedBox(height: 4),
          Center(child: Text('${achievements.totalXp} XP', style: theme.textTheme.titleMedium)),
          const SizedBox(height: 16),
          BadgeDisplay(earnedBadgeIds: resident.decorations),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.emoji_events),
            title: const Text('Achievements'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/achievements'),
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings'),
          ),
          const SizedBox(height: 16),
          ShareCard(
            resident: resident,
            totalXp: achievements.totalXp,
            achievementCount:
                achievements.userAchievements.where((a) => a.status == AchievementStatus.verified).length,
          ),
        ],
      ),
    );
  }
}
