import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/achievements.dart' as ach_config;
import '../../models/channel.dart';
import '../../models/post.dart';
import '../../state/channel_provider.dart';
import '../../state/chat_provider.dart';
import '../../state/resident_provider.dart';
import '../../state/world_provider.dart';
import '../../theme/v_tokens.dart';
import '../../ui/buttons/v_button.dart';
import '../../ui/overlays/v_sheet.dart';
import '../../widgets/core/v_feedback.dart';
import '../../widgets/feed/badge_reaction_picker.dart';
import '../../widgets/worlds/world_icon.dart';

/// Cross-post an achievement-highlighted feed post to a world channel (DCX-096).
Future<void> showCrossPostAchievementSheet(
  BuildContext context, {
  required Post post,
  required Set<String> activeReactions,
}) {
  return showVSheet(
    context,
    CrossPostAchievementSheet(post: post, activeReactions: activeReactions),
    maxSize: 0.85,
  );
}

class CrossPostAchievementSheet extends ConsumerStatefulWidget {
  final Post post;
  final Set<String> activeReactions;

  const CrossPostAchievementSheet({
    super.key,
    required this.post,
    required this.activeReactions,
  });

  @override
  ConsumerState<CrossPostAchievementSheet> createState() =>
      _CrossPostAchievementSheetState();
}

class _CrossPostAchievementSheetState
    extends ConsumerState<CrossPostAchievementSheet> {
  String? _selectedWorldId;
  String? _selectedChannelId;
  bool _sending = false;

  String? get _achievementId {
    for (final key in widget.activeReactions) {
      final id = achievementIdFromBadgeReaction(key);
      if (id != null) return id;
    }
    for (final key in widget.post.reactions.keys) {
      final id = achievementIdFromBadgeReaction(key);
      if (id != null) return id;
    }
    return null;
  }

  Future<void> _send() async {
    final worldId = _selectedWorldId;
    final channelId = _selectedChannelId;
    final resident = ref.read(residentProvider).resident;
    if (worldId == null || channelId == null || resident == null) return;

    setState(() => _sending = true);

    final achId = _achievementId;
    final ach = achId == null ? null : ach_config.achievementForId(achId);
    final buffer = StringBuffer();
    if (ach != null) {
      buffer.write('🏆 Achievement: ${ach.title} (+${ach.xpValue} XP)\n');
      buffer.write('${ach.description}\n\n');
    }
    final snippet = widget.post.content.trim();
    if (snippet.isNotEmpty) {
      buffer.write('From Nexus — $snippet');
    } else if (ach == null) {
      buffer.write('Shared from Nexus');
    }

    await ref.read(chatProvider.notifier).sendChannelMessage(
          worldId: worldId,
          channelId: channelId,
          senderId: resident.id,
          senderName: resident.name,
          senderAvatar: resident.avatarUrl,
          content: buffer.toString().trim(),
        );

    if (!mounted) return;
    setState(() => _sending = false);
    Navigator.of(context).pop();
    VFeedback.showMessage(context, 'Posted to world channel');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resident = ref.watch(residentProvider).resident;
    final worlds = ref.watch(worldProvider).worlds;
    final joined = resident?.joinedWorldIds ?? const <String>[];

    final achId = _achievementId;
    final ach = achId == null ? null : ach_config.achievementForId(achId);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        VSpacing.lg,
        VSpacing.sm,
        VSpacing.lg,
        VSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Share to world channel',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: VFontWeight.bold,
            ),
          ),
          const SizedBox(height: VSpacing.xs),
          Text(
            ach != null
                ? 'Cross-post "${ach.title}" to a channel in one of your worlds.'
                : 'Cross-post this Nexus post to a world channel.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: VSpacing.lg),
          if (joined.isEmpty)
            Text(
              'Join a world first to share achievements in channels.',
              style: theme.textTheme.bodyMedium,
            )
          else ...[
            Text(
              'World',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: VFontWeight.bold,
              ),
            ),
            const SizedBox(height: VSpacing.sm),
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: joined.length,
                separatorBuilder: (_, _) => const SizedBox(width: VSpacing.sm),
                itemBuilder: (_, i) {
                  final id = joined[i];
                  final world = worlds[id];
                  if (world == null) return const SizedBox.shrink();
                  final selected = _selectedWorldId == id;
                  return GestureDetector(
                    onTap: () {
                      ref.read(channelProvider.notifier).loadChannels(id);
                      setState(() {
                        _selectedWorldId = id;
                        _selectedChannelId = null;
                      });
                    },
                    child: Column(
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: selected
                                ? Border.all(
                                    color: theme.colorScheme.primary,
                                    width: 2,
                                  )
                                : null,
                          ),
                          child: WorldIcon(
                            worldId: world.id,
                            size: VWorldIconSize.dense,
                            circular: true,
                          ),
                        ),
                        const SizedBox(height: VSpacing.xxs),
                        Text(
                          world.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: selected
                                ? VFontWeight.bold
                                : VFontWeight.medium,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            if (_selectedWorldId != null) ...[
              const SizedBox(height: VSpacing.md),
              Text(
                'Channel',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: VFontWeight.bold,
                ),
              ),
              const SizedBox(height: VSpacing.sm),
              ..._channelsForWorld(_selectedWorldId!).map((ch) {
                final selected = _selectedChannelId == ch.id;
                return ListTile(
                  dense: true,
                  selected: selected,
                  leading: Icon(
                    ch.channelType == ChannelType.voice
                        ? Icons.local_fire_department
                        : Icons.tag,
                    size: VIconSize.md,
                  ),
                  title: Text(ch.name),
                  onTap: ch.channelType == ChannelType.voice
                      ? null
                      : () => setState(() => _selectedChannelId = ch.id),
                  enabled: ch.channelType != ChannelType.voice,
                );
              }),
            ],
          ],
          const SizedBox(height: VSpacing.lg),
          VButton(
            onPressed: _sending ||
                    _selectedWorldId == null ||
                    _selectedChannelId == null
                ? null
                : _send,
            isLoading: _sending,
            label: 'Post to channel',
            isFullWidth: true,
          ),
        ],
      ),
    );
  }

  List<WorldChannel> _channelsForWorld(String worldId) {
    return ref.watch(channelProvider).channelsByWorld[worldId] ?? [];
  }
}
