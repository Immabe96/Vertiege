import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/channel.dart';
import '../../router/world_navigation.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../../ui/icons/v_icons.dart';
import '../../widgets/core/empty_state.dart';
import '../../state/channel_provider.dart';

class WorldArchiveScreen extends ConsumerStatefulWidget {
  final String worldId;

  const WorldArchiveScreen({
    super.key,
    required this.worldId,
  });

  @override
  ConsumerState<WorldArchiveScreen> createState() => _WorldArchiveScreenState();
}

class _WorldArchiveScreenState extends ConsumerState<WorldArchiveScreen> {
  @override
  Widget build(BuildContext context) {
    final channelState = ref.watch(channelProvider);
    final channels = (channelState.channelsByWorld[widget.worldId] ?? []);

    // Archive specifically targets informational channels like lore, rules, info
    const archiveChannelNames = {'info', 'rules', 'roles', 'lore', 'history', 'documents'};
    final archiveChannels = channels
        .where((channel) => archiveChannelNames.contains(channel.name.toLowerCase()))
        .toList()
      ..sort((a, b) => a.position.compareTo(b.position));

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (archiveChannels.isEmpty) {
      return AppEmptyState(
        title: 'Empty Archive',
        description: 'No lore or documents have been recorded in this archive yet.',
        icon: Icons.menu_book_outlined,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(VSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8.0, bottom: VSpacing.sm),
            child: Text(
              'The Vault of Ages',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: VFontWeight.bold,
                color: isDark ? VColors.primaryDark : VColors.primary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8.0, bottom: VSpacing.lg),
            child: Text(
              'Explore the foundational knowledge and history of this dominion.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? VColors.onSurfaceVariantDark : VColors.onSurfaceVariant,
              ),
            ),
          ),
          ...archiveChannels.map((channel) => _ArchiveItem(
                channel: channel,
                onTap: () => context.push(worldChannelPath(widget.worldId, channel)),
              )),
        ],
      ),
    );
  }
}

class _ArchiveItem extends StatelessWidget {
  final WorldChannel channel;
  final VoidCallback onTap;

  const _ArchiveItem({required this.channel, required this.onTap});

  IconData get _icon => switch (channel.name.toLowerCase()) {
    'info' => Icons.info_outline,
    'rules' => Icons.gavel_outlined,
    'roles' => Icons.badge_outlined,
    'lore' => Icons.auto_stories,
    'history' => Icons.hourglass_bottom,
    _ => Icons.description_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: VSpacing.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(VRadius.md),
        child: Container(
          padding: const EdgeInsets.all(VSpacing.md),
          decoration: BoxDecoration(
            color: (isDark ? VColors.surfaceContainerDark : VColors.surfaceContainer).withValues(alpha: 0.64),
            borderRadius: BorderRadius.circular(VRadius.md),
            border: Border.all(color: isDark ? VColors.glassBorderDark : VColors.glassBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: (isDark ? VColors.primaryDark : VColors.primary).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(VRadius.md),
                ),
                child: Icon(
                  _icon,
                  color: isDark ? VColors.primaryDark : VColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: VSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      channel.name.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isDark ? VColors.onSurfaceDark : VColors.onSurface,
                        fontWeight: VFontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (channel.description != null && channel.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          channel.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isDark ? VColors.onSurfaceVariantDark : VColors.onSurfaceVariant,
                            fontSize: VFontSize.labelSm,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                VIcons.chevronRight,
                color: isDark ? VColors.outlineVariantDark : VColors.outlineVariant,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
