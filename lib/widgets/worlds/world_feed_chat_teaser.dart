import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/channel.dart';
import '../../state/channel_provider.dart';
import '../../state/chat_provider.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../core/glass_panel.dart';
import '../../ui/buttons/v_button.dart';

/// Compact general-channel preview — preview + open CTA (no composer).
class WorldFeedChatTeaser extends ConsumerStatefulWidget {
  final String worldId;

  const WorldFeedChatTeaser({super.key, required this.worldId});

  @override
  ConsumerState<WorldFeedChatTeaser> createState() =>
      _WorldFeedChatTeaserState();
}

class _WorldFeedChatTeaserState extends ConsumerState<WorldFeedChatTeaser> {
  bool _requestedMessages = false;

  void _ensureGeneralLoaded(List<WorldChannel> channels) {
    if (_requestedMessages) return;
    WorldChannel? general;
    for (final c in channels) {
      if (c.name == 'general') {
        general = c;
        break;
      }
    }
    if (general == null) return;
    _requestedMessages = true;
    ref.read(chatProvider.notifier).loadChannelMessages(general.id);
  }

  void _openChannel(WorldChannel channel) {
    final path = channel.name == 'general'
        ? '/explore/${widget.worldId}/general?id=${channel.id}'
        : '/explore/${widget.worldId}/channel/${channel.id}';
    context.push(path);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final channels =
        ref.watch(channelProvider).channelsByWorld[widget.worldId] ?? [];
    _ensureGeneralLoaded(channels);

    WorldChannel? general;
    for (final c in channels) {
      if (c.name == 'general') {
        general = c;
        break;
      }
    }
    if (general == null) return const SizedBox.shrink();

    final allMessages =
        ref.watch(chatProvider).channelMessages[general.id] ?? [];
    final preview = allMessages.isNotEmpty ? allMessages.last : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        VSpacing.md,
        0,
        VSpacing.md,
        VSpacing.sm,
      ),
      child: VSurfacePanel(
        padding: const EdgeInsets.all(VSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.forum_outlined,
                  size: VIconSize.sm,
                  color: VColors.tertiary,
                ),
                const SizedBox(width: VSpacing.sm),
                Text(
                  '#general',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: VFontWeight.semiBold,
                    color: VColors.tertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: VSpacing.sm),
            Text(
              preview == null
                  ? 'No messages yet — be the first in General.'
                  : '${preview.senderName}: ${preview.content}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? VColors.onSurfaceVariantDark
                    : VColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: VSpacing.sm),
            VButton(
              label: 'Open general chat',
              onPressed: () => _openChannel(general!),
              variant: ButtonVariant.outlined,
              isFullWidth: true,
            ),
          ],
        ),
      ),
    );
  }
}
