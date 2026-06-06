import 'package:flutter/material.dart';
import '../../theme/v_tokens.dart';
import '../../theme/v_colors.dart';
import '../../models/resident.dart';
import '../../services/streak_service.dart';
import '../profile/cosmetic_avatar.dart';
import '../core/shimmer.dart';
import '../../ui/icons/v_icons.dart';

class WorldMemberEntry {
  final Resident resident;
  final int rep;
  final int streak;
  const WorldMemberEntry({
    required this.resident,
    required this.rep,
    this.streak = 0,
  });
}

class WorldMemberRow extends StatelessWidget {
  final List<WorldMemberEntry> members;
  final bool isLoading;
  final int onlineCount;
  final VoidCallback onTap;

  const WorldMemberRow({
    super.key,
    required this.members,
    required this.isLoading,
    required this.onlineCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;
    final displayMembers = members.take(8).toList();
    final remaining = members.length - displayMembers.length;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.md,
        vertical: VSpacing.xs,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(VRadius.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: VSpacing.sm),
          child: Row(
            children: [
              if (isLoading) ...[
                Row(
                  children: List.generate(
                    5,
                    (i) => Padding(
                      padding: EdgeInsets.only(left: i == 0 ? 0 : 4),
                      child: const Pulse(
                        width: 32,
                        height: 32,
                        borderRadius: VRadius.pill,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                SizedBox(
                  height: 40,
                  child: Stack(
                    children: displayMembers.asMap().entries.map((entry) {
                      final member = entry.value;
                      final isCouncil = member.rep >= 5000;
                      final hasStreak = member.streak > 0;
                      final flameColor = hasStreak
                          ? StreakService.getStreakFlameColor(member.streak)
                          : null;
                      return Positioned(
                        left: entry.key * 28.0,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isCouncil
                                      ? VColors.tertiary
                                      : isDark ? VColors.surfaceDark : cs.surface,
                                  width: isCouncil ? 2.5 : 2,
                                ),
                                boxShadow: isCouncil
                                    ? [
                                        BoxShadow(
                                          color: VColors.tertiary.withValues(
                                            alpha: 0.35,
                                          ),
                                          blurRadius: 4,
                                          spreadRadius: 0,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: CosmeticAvatar(
                                imageUrl: member.resident.avatarUrl,
                                seed: member.resident.id,
                                size: 32,
                              ),
                            ),
                            if (hasStreak && flameColor != null)
                              Positioned(
                                right: -4,
                                top: -4,
                                child: Container(
                                  padding: const EdgeInsets.all(1),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? VColors.surfaceDark
                                        : cs.surface,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    StreakService.getStreakFlameIcon(
                                      member.streak,
                                    ),
                                    size: 10,
                                    color: flameColor,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(width: VSpacing.sm),
                if (remaining > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: VSpacing.sm,
                      vertical: VSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(VRadius.pill),
                    ),
                    child: Text(
                      '+$remaining more',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.primary,
                        fontWeight: VFontWeight.bold,
                      ),
                    ),
                  ),
                if (remaining > 0) const SizedBox(width: VSpacing.sm),
                if (onlineCount > 0) ...[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: VColors.success,
                    ),
                  ),
                  const SizedBox(width: VSpacing.xs),
                  Text(
                    '$onlineCount online',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: VColors.success,
                      fontWeight: VFontWeight.regular,
                    ),
                  ),
                ],
              ],
              const Spacer(),
              Icon(VIcons.chevronRight, size: VIconSize.md, color: cs.outline),
            ],
          ),
        ),
      ),
    );
  }
}
