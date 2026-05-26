import 'package:flutter_test/flutter_test.dart';
import 'package:vertiege/config/onboarding_funnel.dart';
import 'package:vertiege/models/achievement.dart';
import 'package:vertiege/models/resident.dart';

Resident _resident({List<String> worlds = const ['w1']}) => Resident(
      id: 'r1',
      name: 'Alex',
      joinedWorldIds: worlds,
    );

void main() {
  group('OnboardingFunnel', () {
    test('tracks completion', () {
      final resident = _resident();
      final achievements = [
        UserAchievement(
          achievementId: 'a1',
          status: AchievementStatus.submitted,
          proofUris: ['file://proof.jpg'],
          submittedAt: 1,
        ),
      ];

      expect(
        OnboardingFunnel.isComplete(
          resident: resident,
          achievements: achievements,
          openedWorld: true,
          openedNexus: true,
        ),
        isTrue,
      );

      expect(
        OnboardingFunnel.isComplete(
          resident: resident,
          achievements: achievements,
          openedWorld: false,
          openedNexus: true,
        ),
        isFalse,
      );
    });

    test('ignores auto-only proof', () {
      expect(
        OnboardingFunnel.hasSubmittedProof(const [
          UserAchievement(
            achievementId: 'a1',
            proofUris: ['auto'],
            submittedAt: 1,
          ),
        ]),
        isFalse,
      );
    });
  });
}
