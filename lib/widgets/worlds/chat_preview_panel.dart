import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/channel.dart';
import '../../state/channel_provider.dart';
import '../../state/chat_provider.dart';
import '../../state/resident_provider.dart';
import '../../theme/v_colors.dart';
import '../../theme/design_system.dart';
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
      padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
      child: GlassPanel(
        padding: const EdgeInsets.all(Spacing.lg),
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
                    borderRadius: BorderRadius.circular(RadiusTokens.sm),
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                const Text(
                  'LIVE CHAT',
                  style: TextStyle(
                    fontSize: FontSizes.labelSm,
                    fontWeight: FontWeights.semiBold,
                    color: VColors.tertiary,
                    letterSpacing: LetterSpacing.label,
                  ),
                ),
                const Spacer(),
                const Text(
                  '#general',
                  style: TextStyle(
                    fontSize: FontSizes.labelSm,
                    color: VColors.outline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacing.md),
            // Messages
            if (messages.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: Spacing.md),
                child: Text(
                  'No messages yet. Start the conversation!',
                  style: TextStyle(
                    fontSize: FontSizes.bodyMd,
                    color: VColors.outline,
                  ),
                ),
              )
            else
              ...messages.map(
                (msg) => Padding(
                  padding: const EdgeInsets.only(bottom: Spacing.sm),
                  child: RichText(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: msg.senderName,
                          style: const TextStyle(
                            fontSize: FontSizes.labelSm,
                            fontWeight: FontWeights.semiBold,
                            color: VColors.primary,
                          ),
                        ),
                        TextSpan(
                          text: '  ${msg.content}',
                          style: TextStyle(
                            fontSize: FontSizes.bodyMd,
                            color: isDark ? VColors.onSurfaceDark : VColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: Spacing.md),
            // Input bar
            GlassPanel(
              blur: 8,
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.md,
                vertical: Spacing.xs,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: TextStyle(
                        fontSize: FontSizes.bodyMd,
                        color: isDark ? VColors.onSurfaceDark : VColors.onSurface,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(
                          fontSize: FontSizes.bodyMd,
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
                    icon: const Icon(VIcons.send, size: IconSizes.sm),
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
            const SizedBox(height: Spacing.md),
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
