import 'package:flutter/material.dart';

import '../../theme/v_commune_colors.dart';
import '../../theme/v_tokens.dart';
import '../../utils/haptics.dart';

/// Quick emoji reactions under a post — no sheet required (DCX-088).
class InlineReactionBar extends StatelessWidget {
  static const quickKeys = ['fire', 'heart', 'clap', 'trophy'];

  final Set<String> activeReactions;
  final ValueChanged<String> onReact;
  final bool enabled;

  const InlineReactionBar({
    super.key,
    required this.activeReactions,
    required this.onReact,
    this.enabled = true,
  });

  IconData _iconFor(String key) => switch (key) {
    'fire' => Icons.local_fire_department_outlined,
    'heart' => Icons.favorite_border,
    'clap' => Icons.waving_hand_outlined,
    'trophy' => Icons.emoji_events_outlined,
    _ => Icons.add_reaction_outlined,
  };

  IconData _activeIconFor(String key) => switch (key) {
    'fire' => Icons.local_fire_department,
    'heart' => Icons.favorite,
    'clap' => Icons.waving_hand,
    'trophy' => Icons.emoji_events,
    _ => Icons.add_reaction,
  };

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final key in quickKeys) ...[
          _QuickReaction(
            icon: activeReactions.contains(key)
                ? _activeIconFor(key)
                : _iconFor(key),
            active: activeReactions.contains(key),
            onTap: enabled
                ? () {
                    Haptics.light();
                    onReact(key);
                  }
                : null,
          ),
          if (key != quickKeys.last) const SizedBox(width: VSpacing.xs),
        ],
      ],
    );
  }
}

class _QuickReaction extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback? onTap;

  const _QuickReaction({
    required this.icon,
    required this.active,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active
          ? VCommuneColors.modifierSelected
          : VCommuneColors.modifierHover.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(VRadius.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(VRadius.pill),
        child: Padding(
          padding: const EdgeInsets.all(VSpacing.xs),
          child: Icon(
            icon,
            size: VIconSize.base,
            color: active
                ? VCommuneColors.textLink
                : VCommuneColors.textMuted,
          ),
        ),
      ),
    );
  }
}
