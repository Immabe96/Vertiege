import 'package:flutter/material.dart';
import '../../theme/design_system.dart';
import '../../theme/colors.dart';
import '../../models/resident.dart';
import '../profile/cosmetic_avatar.dart';
import '../core/shimmer.dart';

class WorldMemberEntry {
  final Resident resident;
  final int rep;
  const WorldMemberEntry({required this.resident, required this.rep});
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
    final cs = theme.colorScheme;
    final displayMembers = members.take(8).toList();
    final remaining = members.length - displayMembers.length;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.xs,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(RadiusTokens.cardFeatured),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
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
                        borderRadius: RadiusTokens.pill,
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
                      return Positioned(
                        left: entry.key * 28.0,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isCouncil
                                  ? AppColors.tertiary
                                  : cs.surface,
                              width: isCouncil ? 2.5 : 2,
                            ),
                            boxShadow: isCouncil
                                ? [
                                    BoxShadow(
                                      color: AppColors.tertiary.withValues(
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
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                if (remaining > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacing.sm,
                      vertical: Spacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(RadiusTokens.pill),
                    ),
                    child: Text(
                      '+$remaining more',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeights.bold,
                      ),
                    ),
                  ),
                if (remaining > 0) const SizedBox(width: Spacing.sm),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.semanticSuccess,
                  ),
                ),
                const SizedBox(width: Spacing.xs),
                Text(
                  '$onlineCount online',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.semanticSuccess,
                    fontWeight: FontWeights.regular,
                  ),
                ),
              ],
              const Spacer(),
              Icon(Icons.chevron_right, size: IconSizes.md, color: cs.outline),
            ],
          ),
        ),
      ),
    );
  }
}
