import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ReactionBar extends StatefulWidget {
  final Map<String, int> reactions;
  final String currentResidentId;
  final ValueChanged<String> onReact;

  const ReactionBar({
    super.key,
    required this.reactions,
    required this.currentResidentId,
    required this.onReact,
  });

  @override
  State<ReactionBar> createState() => _ReactionBarState();
}

class _ReactionBarState extends State<ReactionBar> {
  static const _emojis = ['fire', 'diamond', 'trophy', 'clap'];

  IconData _iconFor(String emoji) => switch (emoji) {
        'fire' => Icons.local_fire_department,
        'diamond' => Icons.diamond,
        'trophy' => Icons.emoji_events,
        _ => Icons.waving_hand,
      };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      children: _emojis.map((emoji) {
        final count = widget.reactions[emoji] ?? 0;
        return _ReactionChip(
          emoji: emoji,
          icon: _iconFor(emoji),
          count: count,
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onReact(emoji);
          },
        );
      }).toList(),
    );
  }
}

class _ReactionChip extends StatefulWidget {
  final String emoji;
  final IconData icon;
  final int count;
  final VoidCallback onTap;

  const _ReactionChip({
    required this.emoji,
    required this.icon,
    required this.count,
    required this.onTap,
  });

  @override
  State<_ReactionChip> createState() => _ReactionChipState();
}

class _ReactionChipState extends State<_ReactionChip> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 0.9), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 40),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _burst() {
    _controller.forward(from: 0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: InputChip(
        label: Text('${widget.count}'),
        avatar: Icon(widget.icon, size: 16),
        onPressed: _burst,
      ),
    );
  }
}
