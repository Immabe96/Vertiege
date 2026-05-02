import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/achievement.dart';
import '../../config/achievements.dart';
import '../../state/achievement_provider.dart';

class SubmitAchievementScreen extends ConsumerStatefulWidget {
  const SubmitAchievementScreen({super.key});

  @override
  ConsumerState<SubmitAchievementScreen> createState() => _SubmitAchievementScreenState();
}

class _SubmitAchievementScreenState extends ConsumerState<SubmitAchievementScreen> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Submit Achievement')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Select an achievement to submit for verification:', style: theme.textTheme.bodyLarge),
          const SizedBox(height: 12),
          ...achievements.map((a) {
            final status = ref.watch(achievementProvider.notifier).getAchievementStatus(a.id);
            return RadioListTile<String>(
              title: Text(a.title),
              subtitle: Text('${a.xpValue} XP • ${a.category.name}'),
              value: a.id,
              groupValue: _selectedId,
              onChanged: status == AchievementStatus.locked ? (v) => setState(() => _selectedId = v) : null,
            );
          }),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _selectedId != null
                ? () {
                    ref.read(achievementProvider.notifier).submitAchievement(_selectedId!, 'manual');
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Achievement submitted for verification')),
                    );
                  }
                : null,
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
