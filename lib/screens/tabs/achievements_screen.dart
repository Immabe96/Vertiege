import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../achievements/achievements_index.dart';

/// Achievements tab root — wraps the existing AchievementsIndexScreen
/// inside VTabPage chrome so it fits the tab shell (no back button).
class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const AchievementsIndexScreen();
  }
}
