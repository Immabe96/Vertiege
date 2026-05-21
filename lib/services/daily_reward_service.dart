import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/v_colors.dart';

/// A single reward that can be granted to the resident.
class DailyReward {
  final String label;
  final int xpValue;
  final IconData icon;
  final Color color;
  final bool isShield;

  const DailyReward({
    required this.label,
    required this.xpValue,
    required this.icon,
    required this.color,
    this.isShield = false,
  });
}

/// Deterministic daily reward service.
///
/// Rewards are seeded by `residentId + today's date` so the same user
/// always gets the same reward on a given day, but it changes daily
/// and differs between users.
class DailyRewardService {
  DailyRewardService._();

  static final _rewards = const [
    DailyReward(
      label: '5 XP',
      xpValue: 5,
      icon: Icons.bolt,
      color: VColors.primary,
    ),
    DailyReward(
      label: '10 XP',
      xpValue: 10,
      icon: Icons.auto_awesome,
      color: VColors.tertiary,
    ),
    DailyReward(
      label: '15 XP',
      xpValue: 15,
      icon: Icons.stars,
      color: VColors.tertiary,
    ),
    DailyReward(
      label: 'Streak Shield',
      xpValue: 0,
      icon: Icons.shield,
      color: VColors.tierHustler,
      isShield: true,
    ),
    DailyReward(
      label: '20 XP',
      xpValue: 20,
      icon: Icons.rocket_launch,
      color: VColors.primary,
    ),
  ];

  // Weighted: smaller XP rewards are more common, shields are rare (~10%)
  static final _weights = const [35, 25, 20, 10, 10];

  /// Returns a deterministic daily reward for the given resident.
  ///
  /// The seed combines the resident ID with today's date so the reward
  /// is consistent within a day but changes daily.
  static DailyReward getDailyReward(String residentId) {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final seed = '$residentId-$today';
    final random = Random(seed.hashCode);

    // Weighted selection
    final totalWeight = _weights.fold<int>(0, (sum, w) => sum + w);
    var roll = random.nextInt(totalWeight);

    for (var i = 0; i < _rewards.length; i++) {
      roll -= _weights[i];
      if (roll < 0) return _rewards[i];
    }

    return _rewards.first; // fallback
  }

  /// Returns the storage key for tracking whether today's reward was claimed.
  static String todayKey() {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return '@daily_reward_$today';
  }
}
