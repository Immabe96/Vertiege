import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../achievements/achievements_index.dart';

/// Achievements hub — pushed from You / trophy wall (not a bottom tab).
class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const AchievementsIndexScreen();
  }
}
