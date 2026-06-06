import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vertiege/ui/ui.dart';

import '../../models/message.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_commune_colors.dart';
import '../../theme/v_tokens.dart';
import 'v_message_reaction_picker.dart';

/// Bottom sheet with reaction row + action tiles for DMs.
void showMessageActionSheet(
  BuildContext context, {
  required List<Widget> actions,
  void Function(String emoji)? onReaction,
}) {
  showVSheet(
    context,
    Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onReaction != null) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              VSpacing.md,
              VSpacing.sm,
              VSpacing.md,
              VSpacing.xs,
            ),
            child: Row(
              children: kDefaultReactionEmojis
                  .take(6)
                  .map(
                    (emoji) => Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          onReaction(emoji);
                        },
                        child: Center(
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 22),
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          Divider(color: VCommuneColors.dividerSubtle, height: 1),
        ],
        ...actions,
        SizedBox(height: MediaQuery.paddingOf(context).bottom),
      ],
    ),
    maxSize: 0.5,
  );
}

List<Widget> buildChannelMessageActions({
  required BuildContext context,
  required ChannelMessage message,
  required bool canPin,
  required VoidCallback onOpenThread,
  void Function(bool pin)? onTogglePin,
}) {
  return [
    VTile(
      prefix: const Icon(Icons.forum_outlined),
      title: const Text('Open thread'),
      onPress: () {
        Navigator.pop(context);
        onOpenThread();
      },
    ),
    VTile(
      prefix: const Icon(Icons.copy_outlined),
      title: const Text('Copy text'),
      onPress: () {
        Clipboard.setData(ClipboardData(text: message.content));
        Navigator.pop(context);
      },
    ),
    if (canPin)
      VTile(
        prefix: Icon(
          message.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
        ),
        title: Text(message.isPinned ? 'Unpin message' : 'Pin message'),
        onPress: () {
          Navigator.pop(context);
          onTogglePin?.call(!message.isPinned);
        },
      ),
    VTile(
      prefix: const Icon(Icons.flag_outlined),
      title: const Text('Report'),
      onPress: () => Navigator.pop(context),
    ),
  ];
}

List<Widget> buildDmMessageActions({
  required BuildContext context,
  required ChannelMessage message,
  required bool isMe,
  required VoidCallback onReply,
  required VoidCallback onEdit,
  required VoidCallback onDelete,
}) {
  return [
    VTile(
      prefix: const Icon(Icons.reply_outlined),
      title: const Text('Reply'),
      onPress: () {
        Navigator.pop(context);
        onReply();
      },
    ),
    VTile(
      prefix: const Icon(Icons.copy_outlined),
      title: const Text('Copy text'),
      onPress: () {
        Clipboard.setData(ClipboardData(text: message.content));
        Navigator.pop(context);
      },
    ),
    if (isMe && !message.isDeleted) ...[
      VTile(
        prefix: const Icon(Icons.edit_outlined),
        title: const Text('Edit'),
        onPress: () {
          Navigator.pop(context);
          onEdit();
        },
      ),
      VTile(
        prefix: const Icon(Icons.delete_outline, color: VColors.error),
        title: const Text('Delete', style: TextStyle(color: VColors.error)),
        onPress: () {
          Navigator.pop(context);
          onDelete();
        },
      ),
    ],
    VTile(
      prefix: const Icon(Icons.flag_outlined),
      title: const Text('Report'),
      onPress: () => Navigator.pop(context),
    ),
  ];
}
