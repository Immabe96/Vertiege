import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/channel.dart';
import '../../state/channel_provider.dart';
import '../../state/chat_provider.dart';
import '../../state/resident_provider.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../core/glass_panel.dart';
import '../../ui/icons/v_icons.dart';
import '../../ui/buttons/v_button.dart';

class ChatPreviewPanel extends ConsumerStatefulWidget {
  final String worldId;
  const ChatPreviewPanel({super.key, required this.worldId});

  @override
  ConsumerState<ChatPreviewPanel> createState() => _ChatPreviewPanelState();
}

class _ChatPreviewPanelState extends ConsumerState<ChatPreviewPanel> {
  final _controller = TextEditingController();
  String? _generalChannelId;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _findAndLoadGeneral();
    });
  }

  void _findAndLoadGeneral() {
    if (_loaded) return;
    final channels =
        ref.read(channelProvider).channelsByWorld[widget.worldId] ?? [];
    WorldChannel? general;
    for (final c in channels) {
      if (c.name == 'general') {
        general = c;
        break;
      }
    }
    if (general != null && mounted) {
      _loaded = true;
      setState(() => _generalChannelId = general!.id);
      ref.read(chatProvider.notifier).loadChannelMessages(general.id);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final content = _controller.text.trim();
    if (content.isEmpty || _generalChannelId == null) return;
    final resident = ref.read(residentProvider).resident;
    if (resident == null) return;

    ref
        .read(chatProvider.notifier)
        .sendChannelMessage(
          worldId: widget.worldId,
          channelId: _generalChannelId!,
          senderId: resident.id,
          senderName: resident.name,
          senderAvatar: resident.avatarUrl,
          content: content,
        );
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (!_loaded) {
      _findAndLoadGeneral();
    }

    final channels =
        ref.watch(channelProvider).channelsByWorld[widget.worldId] ?? [];
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
    final messages = allMessages.length > 4
        ? allMessages.sublist(allMessages.length - 4)
        : allMessages;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: VSpacing.md),
      child: VSurfacePanel(
        padding: const EdgeInsets.all(VSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header with gold bar
            Row(
              children: [
                Container(
                  width: 3,
                  height: 16,
                  decoration: BoxDecoration(
                    color: VColors.tertiary,
                    borderRadius: BorderRadius.circular(VRadius.sm),
                  ),
                ),
                const SizedBox(width: VSpacing.sm),
                const Text(
                  'LIVE CHAT',
                  style: TextStyle(
                    fontSize: VFontSize.labelSm,
                    fontWeight: VFontWeight.semiBold,
                    color: VColors.tertiary,
                    letterSpacing: 0,
                  ),
                ),
                const Spacer(),
                const Text(
                  '#general',
                  style: TextStyle(
                    fontSize: VFontSize.labelSm,
                    color: VColors.outline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: VSpacing.md),
            // Messages
            if (messages.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: VSpacing.md),
                child: Text(
                  'No messages yet. Start the conversation!',
                  style: TextStyle(
                    fontSize: VFontSize.bodyMd,
                    color: VColors.outline,
                  ),
                ),
              )
            else
              ...messages.map(
                (msg) => Padding(
                  padding: const EdgeInsets.only(bottom: VSpacing.sm),
                  child: RichText(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: msg.senderName,
                          style: const TextStyle(
                            fontSize: VFontSize.labelSm,
                            fontWeight: VFontWeight.semiBold,
                            color: VColors.primary,
                          ),
                        ),
                        TextSpan(
                          text: '  ${msg.content}',
                          style: TextStyle(
                            fontSize: VFontSize.bodyMd,
                            color: isDark ? VColors.onSurfaceDark : VColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: VSpacing.md),
            // Input bar (inset surface — no nested panel)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: VSpacing.md,
                vertical: VSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: isDark ? VColors.surfaceDark : VColors.surface,
                borderRadius: BorderRadius.circular(VRadius.md),
                border: Border.all(
                  color: isDark
                      ? VColors.outlineVariantDark.withValues(alpha: 0.4)
                      : VColors.outlineVariant.withValues(alpha: 0.5),
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: TextStyle(
                        fontSize: VFontSize.bodyMd,
                        color: isDark ? VColors.onSurfaceDark : VColors.onSurface,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(
                          fontSize: VFontSize.bodyMd,
                          color: VColors.outline,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  IconButton(
                    onPressed: _sendMessage,
                    icon: const Icon(VIcons.send, size: VIconSize.sm),
                    color: VColors.tertiary,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: VSpacing.md),
            // View Channel button
            VButton(
              label: 'VIEW CHANNEL',
              onPressed: () {
                if (general != null) {
                  context.push(
                    '/explore/${widget.worldId}/general?id=${general.id}',
                  );
                }
              },
              variant: ButtonVariant.outlined,
              isFullWidth: true,
            ),
          ],
        ),
      ),
    );
  }
}
