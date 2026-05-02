import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ReactionBar extends StatelessWidget {
  final Map<String, int> reactions;
  final String currentResidentId;
  final ValueChanged<String> onReact;

  const ReactionBar({
    super.key,
    required this.reactions,
    required this.currentResidentId,
    required this.onReact,
  });

  static const _emojis = ['fire', 'diamond', 'trophy', 'clap'];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      children: _emojis.map((emoji) {
        final count = reactions[emoji] ?? 0;
        final icon = switch (emoji) {
          'fire' => Icons.local_fire_department,
          'diamond' => Icons.diamond,
          'trophy' => Icons.emoji_events,
          _ => Icons.waving_hand,
        };

        return InputChip(
          label: Text('$count'),
          avatar: Icon(icon, size: 16),
          onPressed: () {
            HapticFeedback.lightImpact();
            onReact(emoji);
          },
        );
      }).toList(),
    );
  }
}
