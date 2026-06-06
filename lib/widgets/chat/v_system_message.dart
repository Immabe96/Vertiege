import 'package:flutter/material.dart';

import '../../theme/v_commune_chat_theme.dart';
import '../../theme/v_tokens.dart';
import 'v_message_content.dart';

/// Centered muted pill for joins, leaves, tier ups, and system events.
class VSystemMessage extends StatelessWidget {
  final String content;

  const VSystemMessage({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: VSpacing.xs),
        padding: const EdgeInsets.symmetric(
          horizontal: VSpacing.md,
          vertical: VSpacing.xs,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.85,
        ),
        decoration: VCommuneChatTheme.systemMessageDecoration,
        child: VMessageContent(
          content: content,
          textColor: VCommuneChatTheme.timestampMuted,
          selectable: false,
        ),
      ),
    );
  }
}
