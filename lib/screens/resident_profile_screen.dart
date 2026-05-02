import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/resident_provider.dart';
import '../state/achievement_provider.dart';
import '../widgets/profile/cosmetic_avatar.dart';
import '../widgets/profile/name_banner.dart';
import '../widgets/profile/badge_display.dart';
import '../widgets/shared/tier_icon.dart';

class ResidentProfileScreen extends ConsumerWidget {
  final String residentId;

  const ResidentProfileScreen({super.key, required this.residentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resident = ref.watch(residentProvider).resident;
    final achievements = ref.watch(achievementProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(resident?.name ?? 'Resident')),
      body: resident == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(child: CosmeticAvatar(totalXp: achievements.totalXp, size: 80, imageUrl: resident.avatarUrl)),
                const SizedBox(height: 12),
                Center(child: NameBanner(profession: resident.profession, name: resident.name)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TierIcon(tier: resident.tier.value),
                    const SizedBox(width: 8),
                    Text(resident.tier.label, style: theme.textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: 4),
                Center(child: Text('${achievements.totalXp} XP', style: theme.textTheme.headlineSmall)),
                if (resident.bio.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(resident.bio, style: theme.textTheme.bodyLarge, textAlign: TextAlign.center),
                ],
                const SizedBox(height: 12),
                Center(child: Text('Streak: ${resident.streakCount} days', style: theme.textTheme.bodyMedium)),
                if (resident.decorations.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  BadgeDisplay(earnedBadgeIds: resident.decorations),
                ],
              ],
            ),
    );
  }
}
