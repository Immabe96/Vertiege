import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/message.dart';
import '../../services/world_service.dart';
import '../../state/channel_provider.dart';
import '../../state/post_provider.dart';
import '../../state/resident_provider.dart';
import '../../state/world_provider.dart';
import '../../theme/v_tokens.dart';
import '../../ui/buttons/v_button.dart';
import '../../ui/overlays/v_sheet.dart';
import '../../widgets/core/v_feedback.dart';
import '../../widgets/worlds/world_icon.dart';

/// Cross-post a channel message to a world feed or Nexus (inverse of feed → channel).
Future<void> showCrossPostToFeedSheet(
  BuildContext context, {
  required ChannelMessage message,
  required String sourceWorldId,
  required String sourceChannelName,
}) {
  return showVSheet(
    context,
    CrossPostToFeedSheet(
      message: message,
      sourceWorldId: sourceWorldId,
      sourceChannelName: sourceChannelName,
    ),
    maxSize: 0.85,
  );
}

class CrossPostToFeedSheet extends ConsumerStatefulWidget {
  final ChannelMessage message;
  final String sourceWorldId;
  final String sourceChannelName;

  const CrossPostToFeedSheet({
    super.key,
    required this.message,
    required this.sourceWorldId,
    required this.sourceChannelName,
  });

  @override
  ConsumerState<CrossPostToFeedSheet> createState() =>
      _CrossPostToFeedSheetState();
}

class _CrossPostToFeedSheetState extends ConsumerState<CrossPostToFeedSheet> {
  String? _selectedWorldId;
  bool _posting = false;

  String _composeContent() {
    final snippet = widget.message.content.trim();
    final buffer = StringBuffer();
    buffer.write('From #${widget.sourceChannelName} — ');
    if (snippet.isNotEmpty) {
      buffer.write(snippet);
    } else if (widget.message.imageUrl != null) {
      buffer.write('Shared an image');
    } else {
      buffer.write('Shared a message');
    }
    return buffer.toString().trim();
  }

  Future<void> _post() async {
    final worldId = _selectedWorldId;
    final resident = ref.read(residentProvider).resident;
    if (worldId == null || resident == null) return;

    setState(() => _posting = true);
    await ref.read(postProvider.notifier).addPost(
          worldId: worldId,
          residentId: resident.id,
          residentName: resident.name,
          residentAvatar: resident.avatarUrl,
          content: _composeContent(),
          imageUri: widget.message.imageUrl,
          tierValue: resident.tier.value,
        );

    if (!mounted) return;
    setState(() => _posting = false);
    Navigator.of(context).pop();
    VFeedback.showMessage(
      context,
      worldId == 'nexus' ? 'Posted to Nexus' : 'Posted to world feed',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resident = ref.watch(residentProvider).resident;
    final worlds = ref.watch(worldProvider).worlds;
    final joined = resident?.joinedWorldIds ?? const <String>[];
    final targets = <String>['nexus', ...joined];

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
            'Share to feed',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: VFontWeight.bold,
            ),
          ),
          const SizedBox(height: VSpacing.xs),
          Text(
            'Cross-post this channel message to Nexus or a world feed.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: VSpacing.lg),
          if (targets.isEmpty)
            Text(
              'Join a world first to share channel messages.',
              style: theme.textTheme.bodyMedium,
            )
          else ...[
            Text(
              'Destination',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: VFontWeight.bold,
              ),
            ),
            const SizedBox(height: VSpacing.sm),
            SizedBox(
              height: 88,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: targets.length,
                separatorBuilder: (_, _) => const SizedBox(width: VSpacing.sm),
                itemBuilder: (_, i) {
                  final id = targets[i];
                  final isNexus = WorldService.localOnlyWorldIds.contains(id);
                  final label = isNexus ? 'Nexus' : worlds[id]?.name;
                  if (label == null) return const SizedBox.shrink();
                  final selected = _selectedWorldId == id;
                  return GestureDetector(
                    onTap: () {
                      if (!isNexus) {
                        ref.read(channelProvider.notifier).loadChannels(id);
                      }
                      setState(() => _selectedWorldId = id);
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
                            worldId: id,
                            size: 48,
                            circular: true,
                          ),
                        ),
                        const SizedBox(height: VSpacing.xxs),
                        SizedBox(
                          width: 64,
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: selected
                                  ? VFontWeight.bold
                                  : VFontWeight.medium,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: VSpacing.lg),
          VButton(
            onPressed: _posting || _selectedWorldId == null ? null : _post,
            isLoading: _posting,
            label: 'Post to feed',
            isFullWidth: true,
          ),
        ],
      ),
    );
  }
}
