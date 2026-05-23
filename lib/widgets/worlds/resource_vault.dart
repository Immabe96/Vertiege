import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/channel.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../core/glass_panel.dart';

class ResourceVault extends StatelessWidget {
  final String worldId;
  final List<WorldChannel> channels;
  final bool vaultUnlocked;

  const ResourceVault({
    super.key,
    required this.worldId,
    required this.channels,
    required this.vaultUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    final guideChannels = _guideChannels;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: VSpacing.md),
      child: VSurfacePanel(
        padding: const EdgeInsets.all(VSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  vaultUnlocked
                      ? Icons.folder_special_outlined
                      : Icons.menu_book_outlined,
                  color: vaultUnlocked ? VColors.tertiary : VColors.primary,
                  size: VIconSize.md,
                ),
                const SizedBox(width: VSpacing.sm),
                const Expanded(
                  child: Text(
                    'WORLD GUIDE',
                    style: TextStyle(
                      fontSize: VFontSize.labelSm,
                      fontWeight: VFontWeight.semiBold,
                      color: VColors.onSurface,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                if (vaultUnlocked)
                  const _VaultPill(label: 'VAULT READY')
                else
                  const _VaultPill(label: 'STARTER'),
              ],
            ),
            const SizedBox(height: VSpacing.sm),
            Text(
              vaultUnlocked
                  ? 'Official resources live here first. Use the starter channels to orient new residents.'
                  : 'A quick path through the world before residents jump into general chat.',
              style: const TextStyle(
                fontSize: VFontSize.bodyMd,
                color: VColors.outline,
              ),
            ),
            const SizedBox(height: VSpacing.md),
            if (guideChannels.isEmpty)
              const _VaultEmpty()
            else
              for (final channel in guideChannels)
                _GuideItem(
                  channel: channel,
                  onTap: () => context.push(
                    '/explore/$worldId/${Uri.encodeComponent(channel.name)}'
                    '?id=${Uri.encodeComponent(channel.id)}',
                  ),
                ),
          ],
        ),
      ),
    );
  }

  List<WorldChannel> get _guideChannels {
    const guideNames = {'info', 'rules', 'roles'};
    final result =
        channels
            .where((channel) => guideNames.contains(channel.name.toLowerCase()))
            .toList()
          ..sort((a, b) => a.position.compareTo(b.position));
    return result;
  }
}

class _GuideItem extends StatelessWidget {
  final WorldChannel channel;
  final VoidCallback onTap;

  const _GuideItem({required this.channel, required this.onTap});

  IconData get _icon => switch (channel.name.toLowerCase()) {
    'info' => Icons.info_outline,
    'rules' => Icons.gavel_outlined,
    'roles' => Icons.badge_outlined,
    _ => Icons.description_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: VSpacing.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(VRadius.md),
        child: Container(
          padding: const EdgeInsets.all(VSpacing.md),
          decoration: BoxDecoration(
            color: VColors.surfaceContainer.withValues(alpha: 0.64),
            borderRadius: BorderRadius.circular(VRadius.md),
            border: Border.all(color: VColors.glassBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: VColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(VRadius.md),
                ),
                child: Icon(
                  _icon,
                  color: VColors.primary,
                  size: VIconSize.md,
                ),
              ),
              const SizedBox(width: VSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '# ${channel.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: VColors.onSurface,
                        fontWeight: VFontWeight.semiBold,
                      ),
                    ),
                    if (channel.description != null)
                      Text(
                        channel.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: VColors.outline,
                          fontSize: VFontSize.labelSm,
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: VColors.outline,
                size: VIconSize.md,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VaultPill extends StatelessWidget {
  final String label;

  const _VaultPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: VSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: VColors.tertiary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(VRadius.pill),
        border: Border.all(color: VColors.tertiary.withValues(alpha: 0.24)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: VColors.tertiary,
          fontSize: VFontSize.labelSm,
          fontWeight: VFontWeight.bold,
        ),
      ),
    );
  }
}

class _VaultEmpty extends StatelessWidget {
  const _VaultEmpty();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(VSpacing.md),
      decoration: BoxDecoration(
        color: VColors.surfaceContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(VRadius.md),
        border: Border.all(color: VColors.glassBorder),
      ),
      child: const Text(
        'Starter channels are being prepared for this world.',
        style: TextStyle(color: VColors.outline),
      ),
    );
  }
}
