import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/onboarding_funnel.dart';
import '../../models/resident.dart';
import '../../models/achievement.dart';
import '../../router/world_navigation.dart';
import '../../services/world_service.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../../ui/buttons/v_button.dart';

/// Identity checklist for new residents (funnel: profile → world → Nexus → proof).
class FirstStepsCard extends StatelessWidget {
  final Resident resident;
  final List<UserAchievement> userAchievements;
  final bool openedWorld;
  final bool openedNexus;
  final VoidCallback onDismiss;

  /// When true, sits pinned above the You tab scroll (no outer side padding).
  final bool sticky;

  const FirstStepsCard({
    super.key,
    required this.resident,
    required this.userAchievements,
    required this.openedWorld,
    required this.openedNexus,
    required this.onDismiss,
    this.sticky = false,
  });

  String? get _firstWorldId {
    for (final id in resident.joinedWorldIds) {
      if (WorldService.isRemoteWorldId(id)) return id;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const muted = VColors.onSurfaceVariantDark;

    final profileDone = OnboardingFunnel.profileReady(resident);
    final joinedDone = OnboardingFunnel.hasJoinedWorld(resident);
    final proofDone = OnboardingFunnel.hasSubmittedProof(userAchievements);
    final done = OnboardingFunnel.completedCount(
      resident: resident,
      achievements: userAchievements,
      openedWorld: openedWorld,
      openedNexus: openedNexus,
    );

    return Padding(
      padding: sticky
          ? const EdgeInsets.fromLTRB(
              VSpacing.md,
              VSpacing.sm,
              VSpacing.md,
              VSpacing.sm,
            )
          : const EdgeInsets.fromLTRB(
              VSpacing.lg,
              VSpacing.sm,
              VSpacing.lg,
              0,
            ),
      child: Material(
        color: VColors.surfaceContainerDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VRadius.bento),
          side: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant.withValues(
              alpha: 0.35,
            ),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(VSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Your first steps',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: VFontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: VIconSize.md),
                    tooltip: 'Dismiss',
                    onPressed: onDismiss,
                  ),
                ],
              ),
              Text(
                '$done / ${OnboardingFunnel.totalSteps} · '
                'Join a world → open Chat → submit proof',
                style: theme.textTheme.bodySmall?.copyWith(color: muted),
              ),
              const SizedBox(height: VSpacing.md),
              _StepRow(
                done: profileDone,
                label: 'Create your identity',
              ),
              _StepRow(
                done: joinedDone,
                label: 'Join a world',
                subtitle: joinedDone
                    ? 'You\'re in ${resident.joinedWorldIds.length} world(s)'
                    : 'Browse worlds that match your goals',
                onTap: joinedDone ? null : () => context.go('/worlds'),
              ),
              _StepRow(
                done: openedWorld,
                label: 'Open a world home',
                onTap: openedWorld
                    ? null
                    : () {
                        final id = _firstWorldId;
                        if (id != null) {
                          context.push(exploreWorldPath(id));
                        } else {
                          context.go('/worlds');
                        }
                      },
              ),
              _StepRow(
                done: openedNexus,
                label: 'Check your Nexus feed',
                onTap: openedNexus ? null : () => context.go('/'),
              ),
              _StepRow(
                done: proofDone,
                label: 'Submit achievement proof',
                onTap: proofDone
                    ? null
                    : () => context.push('/achievements/submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final bool done;
  final String label;
  final String? subtitle;
  final VoidCallback? onTap;

  const _StepRow({
    required this.done,
    required this.label,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const muted = VColors.onSurfaceVariantDark;

    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: VSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            done ? Icons.check_circle : Icons.radio_button_unchecked,
            size: VIconSize.md,
            color: done ? VColors.success : muted,
          ),
          const SizedBox(width: VSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: done ? VFontWeight.regular : VFontWeight.semiBold,
                    decoration: done ? TextDecoration.lineThrough : null,
                    color: done ? muted : null,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(color: muted),
                  ),
              ],
            ),
          ),
          if (!done && onTap != null)
            VButton(
              variant: ButtonVariant.text,
              size: ButtonSize.small,
              onPressed: onTap,
              label: 'Go',
            ),
        ],
      ),
    );

    return row;
  }
}
