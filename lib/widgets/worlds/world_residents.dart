import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/tiers.dart';
import '../../models/resident.dart';
import '../../models/world.dart';
import '../../router/world_navigation.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../core/fade_in.dart';
import '../core/shimmer.dart';
import '../profile/cosmetic_avatar.dart';
import '../../ui/buttons/v_button.dart';
import 'world_member_row.dart';

/// Resident list on world Members tab — uses members already loaded on the screen.
class WorldResidents extends StatelessWidget {
  final World world;
  final List<WorldMemberEntry> members;
  final bool isLoading;

  const WorldResidents({
    super.key,
    required this.world,
    required this.members,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final preview = members.take(5).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Residents (${members.length})',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: VSpacing.sm),
        if (isLoading)
          ...List.generate(
            3,
            (_) => Padding(
              padding: const EdgeInsets.only(bottom: VSpacing.sm),
              child: Row(
                children: [
                  const Pulse(
                    width: 40,
                    height: 40,
                    borderRadius: VRadius.pill,
                  ),
                  const SizedBox(width: VSpacing.sm),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Pulse(
                          width: 120,
                          height: VFontSize.bodyMd,
                          borderRadius: VRadius.sm,
                        ),
                        const SizedBox(height: VSpacing.xs),
                        Pulse(
                          width: 72,
                          height: VFontSize.labelSm,
                          borderRadius: VRadius.sm,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        else if (members.isEmpty)
          Text(
            'No residents yet',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? VColors.onSurfaceVariantDark
                  : VColors.onSurfaceVariant,
            ),
          )
        else
          ...preview.asMap().entries.map((entry) {
            final idx = entry.key;
            final member = entry.value;
            final resident = member.resident;
            final standing = getStanding(member.rep);
            final isSovereign = resident.id == world.sovereignId;
            final rankLabel = idx < 3 ? '${idx + 1}' : null;
            final rankColor = idx == 0
                ? VColors.tertiary
                : idx == 1
                ? VColors.outline
                : idx == 2
                ? VColors.outlineVariant
                : null;

            return FadeIn(
              delayMs: idx * 50,
              child: _ResidentRow(
                resident: resident,
                standingTitle: standing.title,
                rep: member.rep,
                isSovereign: isSovereign,
                rankLabel: rankLabel,
                rankColor: rankColor,
                onTap: () => context.push(residentProfilePath(resident.id)),
              ),
            );
          }),
        if (!isLoading && members.length > 5)
          Padding(
            padding: const EdgeInsets.only(top: VSpacing.xs),
            child: VButton(
              label: 'See all ${members.length} members',
              onPressed: () => context.push(
                worldMembersPath(
                  world.id,
                  worldName: world.name,
                  sovereignId: world.sovereignId,
                ),
              ),
              variant: ButtonVariant.text,
            ),
          ),
      ],
    );
  }
}

class _ResidentRow extends StatelessWidget {
  final Resident resident;
  final String standingTitle;
  final int rep;
  final bool isSovereign;
  final String? rankLabel;
  final Color? rankColor;
  final VoidCallback onTap;

  const _ResidentRow({
    required this.resident,
    required this.standingTitle,
    required this.rep,
    required this.isSovereign,
    required this.rankLabel,
    required this.rankColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final muted = isDark
        ? VColors.onSurfaceVariantDark
        : VColors.onSurfaceVariant;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: VSpacing.xs),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  CosmeticAvatar(
                    imageUrl: resident.avatarUrl,
                    seed: resident.id,
                    size: 40,
                  ),
                  if (rankLabel != null && rankColor != null)
                    Text(
                      rankLabel!,
                      style: TextStyle(
                        color: rankColor,
                        fontWeight: VFontWeight.bold,
                        fontSize: VFontSize.bodyMd,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: VSpacing.sm),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            resident.name,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: VFontWeight.medium,
                            ),
                          ),
                        ),
                        if (isSovereign) ...[
                          const SizedBox(width: VSpacing.xs),
                          Icon(
                            Icons.auto_awesome,
                            size: 14,
                            color: theme.colorScheme.primary,
                          ),
                        ],
                      ],
                    ),
                    Text(
                      standingTitle,
                      style: theme.textTheme.labelSmall?.copyWith(color: muted),
                    ),
                  ],
                ),
              ),
              Text(
                'Rep $rep',
                style: theme.textTheme.labelSmall?.copyWith(color: muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
