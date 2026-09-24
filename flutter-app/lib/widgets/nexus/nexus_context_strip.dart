import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/contextual_help_prefs.dart';
import '../../theme/v_commune_colors.dart';
import '../../theme/v_context_colors.dart';
import '../../theme/v_tokens.dart';
import '../core/progression_help_button.dart';

/// Achievement-first context chips at the top of Nexus (DCX-091).
class NexusContextStrip extends StatelessWidget {
  final bool showJoinWorldsCta;
  final bool useCommuneStyle;

  const NexusContextStrip({
    super.key,
    this.showJoinWorldsCta = false,
    this.useCommuneStyle = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        VSpacing.md,
        VSpacing.sm,
        VSpacing.md,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Nexus',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: VFontWeight.semiBold,
                  color: useCommuneStyle
                      ? VCommuneColors.headerPrimary
                      : context.vOnSurface,
                ),
              ),
              const Spacer(),
              const ProgressionHelpButton(
                tooltip: 'How XP, tier & rep work',
              ),
            ],
          ),
          const SizedBox(height: VSpacing.sm),
          if (showJoinWorldsCta)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _ContextChip(
                    label: 'Browse worlds',
                    icon: Icons.explore_outlined,
                    selected: true,
                    useCommuneStyle: useCommuneStyle,
                    onTap: () => context.go('/worlds'),
                  ),
                ],
              ),
            )
          else
            const SizedBox.shrink(),
          FutureBuilder<bool>(
            future: ContextualHelpPrefs.shouldShowContextualHelp(),
            builder: (context, snapshot) {
              if (snapshot.data != true) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: VSpacing.sm),
                child: Text(
                  showJoinWorldsCta
                      ? 'Join a world to unlock your feed and share standing.'
                      : 'Your worlds, quests, and progress — start here.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: useCommuneStyle
                        ? VCommuneColors.textMuted
                        : context.vOnSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ContextChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final bool useCommuneStyle;
  final VoidCallback onTap;

  const _ContextChip({
    required this.label,
    required this.icon,
    this.selected = false,
    this.useCommuneStyle = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = useCommuneStyle
        ? (selected
              ? VCommuneColors.modifierSelected
              : VCommuneColors.surfaceSecondary)
        : (selected
              ? context.vPrimary.withValues(alpha: 0.18)
              : context.vSurfaceContainer);
    final border = useCommuneStyle
        ? VCommuneColors.dividerSubtle
        : context.vOutline.withValues(alpha: 0.35);
    final fg = useCommuneStyle
        ? (selected ? VCommuneColors.headerPrimary : VCommuneColors.textMuted)
        : (selected ? context.vOnSurface : context.vOnSurfaceVariant);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(VRadius.pill),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: VSpacing.sm,
            vertical: VSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(VRadius.pill),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: VIconSize.sm, color: fg),
              const SizedBox(width: VSpacing.xs),
              Text(
                label,
                style: TextStyle(
                  fontSize: VFontSize.labelSm,
                  fontWeight: selected ? VFontWeight.semiBold : VFontWeight.medium,
                  color: fg,
                  height: VLineHeight.label,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
