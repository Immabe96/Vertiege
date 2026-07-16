import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/message.dart';
import '../../state/chat_provider.dart';
import '../../state/resident_provider.dart';
import '../../theme/v_tokens.dart';
import '../../ui/overlays/v_sheet.dart';
import '../../utils/date_format.dart';

/// Lists active threads in a world channel (Wave S4 — threads first-class).
Future<void> showChannelThreadListSheet(
  BuildContext context, {
  required String channelId,
  required String channelName,
  required String worldId,
}) {
  return showVSheet(
    context,
    ChannelThreadListSheet(
      channelId: channelId,
      channelName: channelName,
      worldId: worldId,
    ),
    maxSize: 0.75,
  );
}

class ChannelThreadListSheet extends ConsumerWidget {
  final String channelId;
  final String channelName;
  final String worldId;

  const ChannelThreadListSheet({
    super.key,
    required this.channelId,
    required this.channelName,
    required this.worldId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    ref.watch(chatProvider);
    final notifier = ref.read(chatProvider.notifier);
    final threads = notifier.threadStartersForChannel(channelId);
    final currentUserId = ref.watch(residentProvider).resident?.id;

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
            'Threads in #$channelName',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: VFontWeight.bold,
            ),
          ),
          const SizedBox(height: VSpacing.xs),
          Text(
            threads.isEmpty
                ? 'No active threads yet — reply in a channel message to start one.'
                : '${threads.length} active ${threads.length == 1 ? 'thread' : 'threads'}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: VSpacing.md),
          if (threads.isEmpty)
            const SizedBox.shrink()
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: threads.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, index) {
                  final message = threads[index];
                  final threadId = message.id;
                  final unread = notifier.threadUnreadCount(
                    threadId,
                    currentUserId: currentUserId,
                  );
                  return _ThreadRow(
                    message: message,
                    unreadCount: unread,
                    onTap: () => _openThread(context, message),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  void _openThread(BuildContext context, ChannelMessage message) {
    Navigator.of(context).pop();
    context.push(
      '/thread/${message.id}',
      extra: {
        'message': message,
        'channelId': channelId,
        'worldId': worldId,
        'channelName': channelName,
      },
    );
  }
}

class _ThreadRow extends StatelessWidget {
  final ChannelMessage message;
  final int unreadCount;
  final VoidCallback onTap;

  const _ThreadRow({
    required this.message,
    required this.onTap,
    this.unreadCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = message.content.trim();
    final replyLabel = message.threadCount == 1
        ? '1 reply'
        : '${message.threadCount} replies';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(VRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: VSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.senderName,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: VFontWeight.semiBold,
                      ),
                    ),
                    if (preview.isNotEmpty)
                      Text(
                        preview,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: VSpacing.xxs),
                    Text(
                      '$replyLabel · ${formatTimestamp(message.createdAt)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (unreadCount > 0)
                Container(
                  margin: const EdgeInsets.only(right: VSpacing.xs),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(VRadius.pill),
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: VFontWeight.bold,
                    ),
                  ),
                ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
