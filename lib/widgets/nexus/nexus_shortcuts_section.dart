import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../router/progress_navigation.dart';
import '../../services/nexus_shortcut_prefs.dart';
import '../../theme/prestige_noir.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';

/// Collapsible Nexus “Today” strip — collapsed by default so the feed leads.
class NexusShortcutsSection extends ConsumerStatefulWidget {
  const NexusShortcutsSection({super.key});

  @override
  ConsumerState<NexusShortcutsSection> createState() =>
      _NexusShortcutsSectionState();
}

class _NexusShortcutsSectionState extends ConsumerState<NexusShortcutsSection> {
  bool _expanded = false;
  bool _prefsLoaded = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadExpanded());
  }

  Future<void> _loadExpanded() async {
    final expanded = await NexusShortcutPrefs.isTodayExpanded();
    if (!mounted) return;
    setState(() {
      _expanded = expanded;
      _prefsLoaded = true;
    });
  }

  Future<void> _toggle() async {
    final next = !_expanded;
    setState(() => _expanded = next);
    await NexusShortcutPrefs.setTodayExpanded(next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        VSpacing.md,
        VSpacing.xs,
        VSpacing.md,
        VSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: PrestigeNoir.surfaceRaised,
            borderRadius: BorderRadius.circular(VRadius.lg),
            child: InkWell(
              onTap: _prefsLoaded ? _toggle : null,
              borderRadius: BorderRadius.circular(VRadius.lg),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: VSpacing.md,
                  vertical: VSpacing.sm,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.wb_sunny_outlined,
                      size: VIconSize.md,
                      color: VColors.brand,
                    ),
                    const SizedBox(width: VSpacing.sm),
                    Expanded(
                      child: Text(
                        'Today',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: VFontWeight.semiBold,
                          color: PrestigeNoir.foreground,
                        ),
                      ),
                    ),
                    Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      color: PrestigeNoir.muted,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: VSpacing.sm),
            Row(
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
              ],
            ),
          ],
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
