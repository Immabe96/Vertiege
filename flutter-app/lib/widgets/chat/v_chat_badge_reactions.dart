import 'package:flutter/material.dart';
import '../../config/achievements.dart' as ach_config;
import '../../theme/v_tokens.dart';
import '../../utils/haptics.dart';
import '../achievements/achievement_category_meta.dart';
import '../achievements/achievement_icon.dart';
import '../feed/badge_reaction_picker.dart';

/// Inline reaction chips for world-channel messages (emoji + badge reactions).
class VChatBadgeReactions extends StatelessWidget {
  final Map<String, List<String>> reactions;
  final String currentUserId;
  final ValueChanged<String> onToggle;

  const VChatBadgeReactions({
    super.key,
    required this.reactions,
    required this.currentUserId,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (reactions.isEmpty) return const SizedBox.shrink();

    final keys = reactions.entries
        .where((e) => e.value.isNotEmpty)
        .map((e) => e.key)
        .toList()
      ..sort();

    return Padding(
      padding: const EdgeInsets.only(top: VSpacing.xs),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: keys.map((key) {
          final users = reactions[key] ?? const [];
          final count = users.length;
          if (count == 0) return const SizedBox.shrink();
          final isActive = users.contains(currentUserId);

          if (isBadgeReactionKey(key)) {
            final achId = achievementIdFromBadgeReaction(key);
            final ach =
                achId == null ? null : ach_config.achievementForId(achId);
            if (ach == null) return const SizedBox.shrink();
            final meta = metaForCategory(ach.category);
            return InputChip(
              label: Text('$count'),
              avatar: AchievementBadgeAvatar(
                achievement: ach,
                accentColor: meta.color,
                size: VIconSize.lgMd,
                showEarnedBadge: true,
              ),
              onPressed: () {
                Haptics.light();
                onToggle(key);
              },
              showCheckmark: false,
              backgroundColor: isActive
                  ? Theme.of(context).colorScheme.primaryContainer
                  : null,
            );
          }

          return InputChip(
            label: Text('$key $count'),
            onPressed: () {
              Haptics.light();
              onToggle(key);
            },
            showCheckmark: false,
            backgroundColor: isActive
                ? Theme.of(context).colorScheme.primaryContainer
                : null,
          );
        }).toList(),
      ),
    );
  }
}

/// Opens badge reaction picker for channel messages.
Future<void> showChatBadgeReactionPicker(
  BuildContext context, {
  required ValueChanged<String> onPick,
}) {
  return BadgeReactionPickerSheet.show(
    context,
    reactionKey: onPick,
  );
}
