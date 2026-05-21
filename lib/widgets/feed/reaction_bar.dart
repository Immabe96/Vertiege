import 'package:flutter/material.dart';
import '../../theme/v_colors.dart';
import '../../theme/design_system.dart';
import '../../utils/haptics.dart';

class _ExclusiveReaction {
  final String emoji;
  final String label;
  final IconData icon;
  final int requiredTier;
  final bool animated;

  const _ExclusiveReaction({
    required this.emoji,
    required this.label,
    required this.icon,
    required this.requiredTier,
    this.animated = false,
  });
}

class ReactionBar extends StatefulWidget {
  final Map<String, int> reactions;
  final String currentResidentId;
  final ValueChanged<String> onReact;
  final int userTier;

  const ReactionBar({
    super.key,
    required this.reactions,
    required this.currentResidentId,
    required this.onReact,
    this.userTier = 1,
  });

  @override
  State<ReactionBar> createState() => _ReactionBarState();
}

class _ReactionBarState extends State<ReactionBar> {
  static const _emojis = ['fire', 'diamond', 'trophy', 'clap'];
  static const _allEmojis = [
    'fire',
    'diamond',
    'trophy',
    'clap',
    'heart',
    'laugh',
    'wow',
    'sad',
    'angry',
  ];

  static const _exclusiveReactions = [
    _ExclusiveReaction(
      emoji: 'custom',
      label: 'Custom',
      icon: Icons.palette,
      requiredTier: 2,
    ),
    _ExclusiveReaction(
      emoji: 'elite',
      label: 'Elite',
      icon: Icons.star,
      requiredTier: 3,
    ),
    _ExclusiveReaction(
      emoji: 'royal',
      label: 'Royal',
      icon: Icons.rocket_launch,
      requiredTier: 4,
    ),
    _ExclusiveReaction(
      emoji: 'apex',
      label: 'Apex',
      icon: Icons.diamond,
      requiredTier: 5,
      animated: true,
    ),
  ];

  /// Tracks which reactions the current user has tapped during this session.
  final Set<String> _userReactions = {};

  IconData _iconFor(String emoji) => switch (emoji) {
    'fire' => Icons.local_fire_department,
    'diamond' => Icons.diamond,
    'trophy' => Icons.emoji_events,
    'clap' => Icons.waving_hand,
    'heart' => Icons.favorite,
    'laugh' => Icons.sentiment_very_satisfied,
    'wow' => Icons.emoji_emotions,
    'sad' => Icons.sentiment_dissatisfied,
    'angry' => Icons.sentiment_very_dissatisfied,
    _ => Icons.waving_hand,
  };

  String _labelFor(String emoji) => switch (emoji) {
    'fire' => 'Fire',
    'diamond' => 'Diamond',
    'trophy' => 'Trophy',
    'clap' => 'Clap',
    'heart' => 'Love',
    'laugh' => 'Haha',
    'wow' => 'Wow',
    'sad' => 'Sad',
    'angry' => 'Angry',
    _ => 'React',
  };

  void _onReactionTap(String emoji) {
    Haptics.light();
    setState(() {
      if (_userReactions.contains(emoji)) {
        _userReactions.remove(emoji);
      } else {
        _userReactions.add(emoji);
      }
    });
    widget.onReact(emoji);
  }

  void _onLockedReactionTap(_ExclusiveReaction reaction) {
    Haptics.light();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Unlock ${reaction.label} at Tier ${reaction.requiredTier}'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showLongPressMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return Container(
          decoration: BoxDecoration(
            color: VColors.glassBackground,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(RadiusTokens.cardFeatured),
            ),
            border: Border.all(color: VColors.glassBorder),
          ),
          padding: const EdgeInsets.all(Spacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: Spacing.sm),
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(RadiusTokens.sm),
                ),
              ),
              Text('Choose a reaction', style: theme.textTheme.titleSmall),
              const SizedBox(height: Spacing.md),
              Wrap(
                spacing: Spacing.md,
                runSpacing: Spacing.sm,
                children: [
                  ..._allEmojis.map((emoji) {
                    final isActive = _userReactions.contains(emoji);
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        _onReactionTap(emoji);
                      },
                      child: AnimatedContainer(
                        duration: AnimDurations.fast,
                        padding: const EdgeInsets.all(Spacing.md),
                        decoration: BoxDecoration(
                          color: isActive
                              ? theme.colorScheme.primaryContainer
                              : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(RadiusTokens.card),
                          border: isActive
                              ? Border.all(
                                  color: theme.colorScheme.primary,
                                  width: 1.5,
                                )
                              : null,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _iconFor(emoji),
                              size: IconSizes.xl,
                              color: isActive
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface,
                            ),
                            const SizedBox(height: Spacing.xs),
                            Text(
                              _labelFor(emoji),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: isActive
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface,
                                fontWeight: isActive
                                    ? FontWeights.bold
                                    : FontWeights.regular,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: Spacing.sm),
                  ..._exclusiveReactions.map((reaction) {
                    final isUnlocked = widget.userTier >= reaction.requiredTier;
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        if (isUnlocked) {
                          _onReactionTap(reaction.emoji);
                        } else {
                          _onLockedReactionTap(reaction);
                        }
                      },
                      child: AnimatedContainer(
                        duration: AnimDurations.fast,
                        padding: const EdgeInsets.all(Spacing.md),
                        decoration: BoxDecoration(
                          color: isUnlocked
                              ? VColors.tertiary.withValues(alpha: 0.15)
                              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(RadiusTokens.card),
                          border: isUnlocked
                              ? Border.all(color: VColors.tertiary.withValues(alpha: 0.4))
                              : null,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Icon(
                                  reaction.icon,
                                  size: IconSizes.xl,
                                  color: isUnlocked
                                      ? VColors.tertiary
                                      : theme.colorScheme.outline,
                                ),
                                if (!isUnlocked)
                                  Icon(
                                    Icons.lock,
                                    size: 12,
                                    color: theme.colorScheme.outline,
                                  ),
                              ],
                            ),
                            const SizedBox(height: Spacing.xs),
                            Text(
                              reaction.label,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: isUnlocked
                                    ? VColors.tertiary
                                    : theme.colorScheme.outline,
                                fontWeight: FontWeights.regular,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
              const SizedBox(height: Spacing.md),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: _showLongPressMenu,
      behavior: HitTestBehavior.opaque,
      child: Wrap(
        spacing: 6,
        children: _emojis.map((emoji) {
          final count = widget.reactions[emoji] ?? 0;
          final isActive = _userReactions.contains(emoji);
          return _ReactionChip(
            emoji: emoji,
            icon: _iconFor(emoji),
            count: count,
            isActive: isActive,
            onTap: () => _onReactionTap(emoji),
          );
        }).toList(),
      ),
    );
  }
}

class _ReactionChip extends StatefulWidget {
  final String emoji;
  final IconData icon;
  final int count;
  final bool isActive;
  final VoidCallback onTap;

  const _ReactionChip({
    required this.emoji,
    required this.icon,
    required this.count,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_ReactionChip> createState() => _ReactionChipState();
}

class _ReactionChipState extends State<_ReactionChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
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
    final theme = Theme.of(context);

    return ScaleTransition(
      scale: _scale,
      child: InputChip(
        label: Text('${widget.count}'),
        avatar: Icon(widget.icon, size: 16),
        onPressed: _burst,
        backgroundColor: widget.isActive
            ? theme.colorScheme.primaryContainer
            : null,
        side: widget.isActive
            ? BorderSide(
                color: theme.colorScheme.primary.withValues(alpha: 0.5),
              )
            : null,
        selected: widget.isActive,
        selectedColor: theme.colorScheme.primaryContainer,
        showCheckmark: false,
      ),
    );
  }
}
