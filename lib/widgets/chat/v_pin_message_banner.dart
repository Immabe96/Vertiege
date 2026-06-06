import 'package:flutter/material.dart';
import 'package:vertiege/ui/ui.dart';

import '../../models/message.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_commune_colors.dart';
import '../../theme/v_tokens.dart';
import 'v_message_bubble.dart';

/// Slim pinned-message banner below channel header.
class VPinMessageBanner extends StatelessWidget {
  final List<ChannelMessage> pinnedMessages;
  final String residentId;
  final String worldId;
  final String channelName;
  final bool canPin;
  final void Function(String messageId, bool isPinned)? onTogglePin;

  const VPinMessageBanner({
    super.key,
    required this.pinnedMessages,
    required this.residentId,
    required this.worldId,
    required this.channelName,
    required this.canPin,
    this.onTogglePin,
  });

  @override
  Widget build(BuildContext context) {
    if (pinnedMessages.isEmpty) return const SizedBox.shrink();

    final latest = pinnedMessages.last;
    final snippet = latest.content.replaceAll('\n', ' ').trim();
    final preview = snippet.length > 64
        ? '${snippet.substring(0, 64)}…'
        : snippet;

    return Material(
      color: VCommuneColors.surfaceSecondaryAlt,
      child: InkWell(
        onTap: () => _showAllPins(context),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: VSpacing.md,
            vertical: VSpacing.sm,
          ),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: VCommuneColors.dividerSubtle),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.push_pin,
                size: 14,
                color: VColors.tertiary,
              ),
              const SizedBox(width: VSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pinnedMessages.length == 1
                          ? 'Pinned message'
                          : '${pinnedMessages.length} pinned messages',
                      style: const TextStyle(
                        fontSize: VFontSize.labelSm,
                        fontWeight: VFontWeight.semiBold,
                        color: VColors.tertiary,
                      ),
                    ),
                    if (preview.isNotEmpty)
                      Text(
                        '${latest.senderName}: $preview',
                        style: const TextStyle(
                          fontSize: VFontSize.labelSm,
                          color: VCommuneColors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: VIconSize.sm,
                color: VCommuneColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAllPins(BuildContext context) {
    final animatedIds = <String>{};
    showVSheet(
      context,
      Padding(
        padding: const EdgeInsets.fromLTRB(
          VSpacing.md,
          VSpacing.sm,
          VSpacing.md,
          VSpacing.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Pinned in #$channelName',
              style: const TextStyle(
                fontSize: VFontSize.headlineSm,
                fontWeight: VFontWeight.bold,
                color: VCommuneColors.headerPrimary,
              ),
            ),
            const SizedBox(height: VSpacing.md),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: pinnedMessages
                    .map(
                      (msg) => VMessageBubble(
                        message: msg,
                        isMe: msg.senderId == residentId,
                        showHeader: true,
                        animatedMessageIds: animatedIds,
                        mode: VMessageBubbleMode.channel,
                        channelConfig: VChannelBubbleConfig(
                          isSystem:
                              msg.senderId == 'system' ||
                              msg.senderName == 'System',
                          canPin: canPin,
                          worldId: worldId,
                          channelName: channelName,
                          onTogglePin: onTogglePin,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
      maxSize: 0.7,
    );
  }
}
