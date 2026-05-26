import 'package:flutter/material.dart';

import '../../config/achievements.dart' as ach_config;
import '../../models/achievement.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../../utils/haptics.dart';
import '../../widgets/achievements/achievement_category_meta.dart';
import '../../widgets/achievements/achievement_icon.dart';
import '../../widgets/core/v_feedback.dart';
import 'badge_reaction_picker.dart';

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
  final Set<String>? activeReactions;

  const ReactionBar({
    super.key,
    required this.reactions,
    required this.currentResidentId,
    required this.onReact,
    this.userTier = 1,
    this.activeReactions,
  });

  @override
  State<ReactionBar> createState() => _ReactionBarState();
}

class _ReactionBarState extends State<ReactionBar> {
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

  Set<String> get _active => widget.activeReactions ?? _userReactions;

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
    if (widget.activeReactions == null) {
      setState(() {
        if (_userReactions.contains(emoji)) {
          _userReactions.remove(emoji);
        } else {
          _userReactions.add(emoji);
        }
      });
    }
    widget.onReact(emoji);
  }

  void _onLockedReactionTap(_ExclusiveReaction reaction) {
    Haptics.light();
    VFeedback.showMessage(context, 'Unlock ${reaction.label} at Tier ${reaction.requiredTier}');
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
              top: Radius.circular(VRadius.md),
            ),
            border: Border.all(color: VColors.glassBorder),
          ),
          padding: const EdgeInsets.all(VSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: VSpacing.sm),
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(VRadius.sm),
                ),
              ),
              Text('Choose a reaction', style: theme.textTheme.titleSmall),
              const SizedBox(height: VSpacing.md),
              Wrap(
                spacing: VSpacing.md,
                runSpacing: VSpacing.sm,
                children: [
                  ..._allEmojis.map((emoji) {
                    final isActive = _userReactions.contains(emoji);
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        _onReactionTap(emoji);
                      },
                      child: AnimatedContainer(
                        duration: VAnimation.fast,
                        padding: const EdgeInsets.all(VSpacing.md),
                        decoration: BoxDecoration(
                          color: isActive
                              ? theme.colorScheme.primaryContainer
                              : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(VRadius.lg),
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
                              size: VIconSize.xl,
                              color: isActive
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface,
                            ),
                            const SizedBox(height: VSpacing.xs),
                            Text(
                              _labelFor(emoji),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: isActive
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface,
                                fontWeight: isActive
                                    ? VFontWeight.bold
                                    : VFontWeight.regular,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: VSpacing.sm),
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
                        duration: VAnimation.fast,
                        padding: const EdgeInsets.all(VSpacing.md),
                        decoration: BoxDecoration(
                          color: isUnlocked
                              ? VColors.tertiary.withValues(alpha: 0.15)
                              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(VRadius.lg),
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
                                  size: VIconSize.xl,
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
                            const SizedBox(height: VSpacing.xs),
                            Text(
                              reaction.label,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: isUnlocked
                                    ? VColors.tertiary
                                    : theme.colorScheme.outline,
                                fontWeight: VFontWeight.regular,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
              const SizedBox(height: VSpacing.md),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final keys = widget.reactions.entries
        .where((e) => e.value > 0)
        .map((e) => e.key)
        .toList()
      ..sort();

    return GestureDetector(
      onLongPress: _showLongPressMenu,
      behavior: HitTestBehavior.opaque,
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: keys.map((key) {
          final count = widget.reactions[key] ?? 0;
          final isActive = _active.contains(key);
          if (isBadgeReactionKey(key)) {
            final achId = achievementIdFromBadgeReaction(key);
            final ach =
                achId == null ? null : ach_config.achievementForId(achId);
            if (ach == null) return const SizedBox.shrink();
            final meta = metaForCategory(ach.category);
            return _BadgeReactionChip(
              count: count,
              isActive: isActive,
              achievement: ach,
              accentColor: meta.color,
              onTap: () => _onReactionTap(key),
            );
          }
          return _ReactionChip(
            emoji: key,
            icon: _iconFor(key),
            count: count,
            isActive: isActive,
            onTap: () => _onReactionTap(key),
          );
        }).toList(),
      ),
    );
  }
}

class _BadgeReactionChip extends StatelessWidget {
  final int count;
  final bool isActive;
  final Achievement achievement;
  final Color accentColor;
  final VoidCallback onTap;

  const _BadgeReactionChip({
    required this.count,
    required this.isActive,
    required this.achievement,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InputChip(
      label: Text('$count'),
      avatar: AchievementBadgeAvatar(
        achievement: achievement,
        accentColor: accentColor,
        size: 22,
        showEarnedBadge: true,
      ),
      onPressed: onTap,
      backgroundColor:
          isActive ? theme.colorScheme.primaryContainer : null,
      showCheckmark: false,
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
