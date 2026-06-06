import 'package:flutter/material.dart';

import '../../models/achievement.dart';
import '../../models/resident.dart';
import '../../theme/v_tokens.dart';
import '../../ui/overlays/v_sheet.dart';
import 'trophy_case.dart';

/// Full trophy case in a bottom sheet (Wave 20 — no extra route).
void showTrophyCaseSheet(
  BuildContext context, {
  required Resident resident,
  required List<UserAchievement> achievements,
  required int totalXp,
}) {
  showVSheet(
    context,
    Padding(
      padding: const EdgeInsets.fromLTRB(
        VSpacing.md,
        VSpacing.sm,
        VSpacing.md,
        VSpacing.xl,
      ),
      child: TrophyCase(
        resident: resident,
        achievements: achievements,
        totalXp: totalXp,
      ),
    ),
    maxSize: 0.92,
  );
}
