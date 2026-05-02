import 'package:flutter/material.dart';
import '../../models/achievement.dart';
import '../../theme/colors.dart';

class AchievementCard extends StatelessWidget {
  final Achievement achievement;
  final AchievementStatus status;
  final VoidCallback? onPress;

  const AchievementCard({
    super.key,
    required this.achievement,
    required this.status,
    this.onPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = switch (status) {
      AchievementStatus.verified => AppColors.emerald,
      AchievementStatus.submitted => AppColors.seed,
      AchievementStatus.locked => Colors.transparent,
    };

    return Card(
      color: status == AchievementStatus.locked
          ? theme.colorScheme.surfaceContainerHighest
          : theme.colorScheme.surface,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.15),
          child: Icon(Icons.emoji_events, color: statusColor),
        ),
        title: Text(achievement.title, style: theme.textTheme.labelLarge),
        subtitle: Text(achievement.description, style: theme.textTheme.bodySmall),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${achievement.xpValue} XP',
                style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600)),
            if (status == AchievementStatus.submitted)
              Text('Pending', style: TextStyle(color: AppColors.seed, fontSize: 10)),
          ],
        ),
        onTap: status != AchievementStatus.verified ? onPress : null,
      ),
    );
  }
}
