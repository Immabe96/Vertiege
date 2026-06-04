import 'package:flutter/material.dart';

import '../../models/achievement.dart';
import '../../models/resident.dart';
import '../../theme/v_tokens.dart';
import 'trophy_case.dart';

/// Full trophy case in a bottom sheet (Wave 20 — no extra route).
void showTrophyCaseSheet(
  BuildContext context, {
  required Resident resident,
  required List<UserAchievement> achievements,
  required int totalXp,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      builder: (_, scrollController) => ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(
          VSpacing.md,
          0,
          VSpacing.md,
          VSpacing.xl,
        ),
        children: [
          TrophyCase(
            resident: resident,
            achievements: achievements,
            totalXp: totalXp,
          ),
        ],
      ),
    ),
  );
}
