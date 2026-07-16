import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../router/progress_navigation.dart';
import '../../services/nexus_shortcut_prefs.dart';
import '../../theme/prestige_noir.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';

/// Lean Nexus “Today” strip — streak + quest + Progress hub. Feed stays primary.
class NexusShortcutsSection extends ConsumerWidget {
  const NexusShortcutsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        VSpacing.md,
        VSpacing.xs,
        VSpacing.md,
        VSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: _TodayChip(
              icon: Icons.local_fire_department,
              label: 'Streak',
              onTap: () => _open(context, 'streak', progressPath()),
            ),
          ),
          const SizedBox(width: VSpacing.sm),
          Expanded(
            child: _TodayChip(
              icon: Icons.flag_outlined,
              label: 'Quests',
              onTap: () => _open(
                context,
                'quest',
                progressPath(tab: ProgressTab.quests),
              ),
            ),
          ),
          const SizedBox(width: VSpacing.sm),
          Expanded(
            child: _TodayChip(
              icon: Icons.insights_outlined,
              label: 'Progress',
              onTap: () => _open(context, 'progress', progressPath()),
            ),
          ),
          const SizedBox(width: VSpacing.sm),
          Expanded(
            child: _TodayChip(
              icon: Icons.public,
              label: 'Worlds',
              onTap: () {
                unawaited(NexusShortcutPrefs.recordVisit('worlds'));
                context.go('/worlds');
              },
            ),
          ),
        ],
      ),
    );
  }

  static void _open(BuildContext context, String id, String route) {
    unawaited(NexusShortcutPrefs.recordVisit(id));
    context.push(route);
  }
}

class _TodayChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _TodayChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: PrestigeNoir.surfaceRaised,
      borderRadius: BorderRadius.circular(VRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(VRadius.lg),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: VSpacing.sm,
            vertical: VSpacing.sm,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: VIconSize.md, color: VColors.brand),
              const SizedBox(height: VSpacing.xxs),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: VFontWeight.semiBold,
                  color: PrestigeNoir.foreground,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
