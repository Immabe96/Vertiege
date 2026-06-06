import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vertiege/models/achievement.dart';
import 'package:vertiege/state/achievement_provider.dart';

void main() {
  test('reloadAndCelebrateRemoteVerifications adds newly verified ids', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(achievementProvider.notifier);
    notifier.state = notifier.state.copyWith(
      isLoading: false,
      userAchievements: const [
        UserAchievement(
          achievementId: 'a1',
          status: AchievementStatus.submitted,
        ),
      ],
    );

    await notifier.reloadAndCelebrateRemoteVerifications();

    // Offline / no Supabase: loadAchievements may not add verified rows.
    expect(container.read(achievementProvider).recentlyUnlockedIds, isEmpty);
  });
}
