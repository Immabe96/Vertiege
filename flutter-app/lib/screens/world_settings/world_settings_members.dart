import 'package:flutter/material.dart';

import '../../config/tiers.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../../utils/tier_utils.dart';
import '../../widgets/core/loading_state.dart';
import 'world_settings_card.dart';

class WorldSettingsMembers extends StatelessWidget {
  final List<Map<String, dynamic>> members;
  final bool isLoading;
  final String sovereignId;
  final String? currentResidentId;
  final bool canModerate;
  final void Function(String residentId, String name, int hours) onMute;
  final void Function(String residentId, String name) onBan;

  const WorldSettingsMembers({
    super.key,
    required this.members,
    required this.isLoading,
    required this.sovereignId,
    required this.currentResidentId,
    required this.canModerate,
    required this.onMute,
    required this.onBan,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return WorldSettingsCard(
      padding: const EdgeInsets.all(VSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.group, color: VColors.tertiary, size: VIconSize.md),
              const SizedBox(width: VSpacing.sm),
              Text(
                'Residents',
                style: TextStyle(
                  fontSize: VFontSize.bodyMd,
                  fontWeight: VFontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: VSpacing.sm),
          Text(
            'Manage residents and their standing in this world.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: VSpacing.md),
          if (isLoading)
            const Center(child: VLoadingCard())
          else if (members.isEmpty)
            Text(
              'No residents found',
              style: theme.textTheme.bodyMedium,
            )
          else
            ...members.map((m) {
              final residentId = m['resident_id'] as String? ?? '';
              final name = m['resident_name'] as String? ?? 'Member';
              final rep = m['rep'] as int? ?? 0;
              final standing = getStanding(rep);
              final isSovereign = residentId == sovereignId;
              final isCurrentUser = residentId == currentResidentId;

              return Padding(
                padding: const EdgeInsets.only(bottom: VSpacing.sm),
                child: WorldSettingsCard(
                  padding: const EdgeInsets.all(VSpacing.md),
                  borderRadius: BorderRadius.circular(VRadius.xl),
                  child: Row(
                    children: [
                      CircleAvatar(
                        child: Text(name.substring(0, 1).toUpperCase()),
                      ),
                      const SizedBox(width: VSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    name,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: VFontWeight.semiBold,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                if (isSovereign) ...[
                                  const SizedBox(width: VSpacing.sm),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: VSpacing.sm,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: VColors.tertiary,
                                      borderRadius:
                                          BorderRadius.circular(VRadius.pill),
                                    ),
                                    child: Text(
                                      'SOVEREIGN',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: VColors.onTertiary,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: VSpacing.xs),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: VSpacing.sm,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: tierStandingColor(
                                      standing.level,
                                    ).withValues(alpha: 0.15),
                                    borderRadius:
                                        BorderRadius.circular(VRadius.pill),
                                  ),
                                  child: Text(
                                    standing.title,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: tierStandingColor(standing.level),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: VSpacing.sm),
                                Text(
                                  'Rep $rep',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: VColors.tertiary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (!isCurrentUser && canModerate)
                        PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_vert,
                            size: VIconSize.base,
                            color: theme.colorScheme.outlineVariant,
                          ),
                          onSelected: (action) {
                            switch (action) {
                              case 'mute1':
                                onMute(residentId, name, 1);
                              case 'mute24':
                                onMute(residentId, name, 24);
                              case 'ban':
                                onBan(residentId, name);
                            }
                          },
                          itemBuilder: (ctx) => const [
                            PopupMenuItem(
                              value: 'mute1',
                              child: Text('Mute 1 hour'),
                            ),
                            PopupMenuItem(
                              value: 'mute24',
                              child: Text('Mute 24 hours'),
                            ),
                            PopupMenuItem(
                              value: 'ban',
                              child: Text('Ban'),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
