import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/message.dart';
import '../../state/chat_provider.dart';
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
    final threads =
        ref.read(chatProvider.notifier).threadStartersForChannel(channelId);

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
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, index) => _ThreadRow(
                  message: threads[index],
                  onTap: () => _openThread(context, threads[index]),
                ),
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
  final VoidCallback onTap;

  const _ThreadRow({required this.message, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = message.content.trim();
    final replyLabel = message.threadCount == 1
        ? '1 reply'
        : '${message.threadCount} replies';

    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      title: Text(
        message.senderName,
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: VFontWeight.semiBold,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
      trailing: const Icon(Icons.chevron_right),
    );
  }
}
