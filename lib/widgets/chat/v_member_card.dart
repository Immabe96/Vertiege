import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/tiers.dart';
import '../../router/world_navigation.dart';
import '../../theme/v_commune_colors.dart';
import '../../theme/v_tokens.dart';
import '../../utils/standing_display_color.dart';
import '../core/status_dot.dart';
import '../profile/cosmetic_avatar.dart';
import '../shared/tier_icon.dart';

/// Rich resident card — reputation, tier, standing, DM CTA (DCX-143).
class VMemberCard extends StatelessWidget {
  final String residentId;
  final String name;
  final int rep;
  final int tier;
  final String? profession;
  final String? avatarUrl;
  final String? avatarFrameId;
  final int totalXp;
  final String? sovereignId;
  final Presence? presence;
  final bool identityVerified;
  final String? customStatus;
  final VoidCallback? onMessage;
  final VoidCallback? onDismiss;

  const VMemberCard({
    super.key,
    required this.residentId,
    required this.name,
    required this.rep,
    required this.tier,
    this.profession,
    this.avatarUrl,
    this.avatarFrameId,
    this.totalXp = 0,
    this.sovereignId,
    this.presence,
    this.identityVerified = false,
    this.customStatus,
    this.onMessage,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final standing = getStanding(rep);
    final nameColor = standingDisplayColor(
      rep,
      sovereignId: sovereignId,
      residentId: residentId,
    );
    final tierLabel = tierNames[tier] ?? 'Tier $tier';

    return Material(
      color: VCommuneColors.surfaceSecondary,
      borderRadius: BorderRadius.circular(VRadius.lg),
      child: Padding(
        padding: const EdgeInsets.all(VSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CosmeticAvatar(
                      imageUrl: avatarUrl,
                      seed: residentId,
                      size: 52,
                      totalXp: totalXp,
                      frameId: avatarFrameId,
                    ),
                    if (presence != null)
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: StatusDot(presence: presence!, size: 12),
                      ),
                  ],
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
                              style: TextStyle(
                                fontSize: VFontSize.headlineSm,
                                fontWeight: VFontWeight.bold,
                                color: nameColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (identityVerified) ...[
                            const SizedBox(width: VSpacing.xxs),
                            const Icon(
                              Icons.verified,
                              size: VIconSize.base,
                              color: VCommuneColors.textLink,
                            ),
                          ],
                          const SizedBox(width: VSpacing.xs),
                          TierIcon(tier: tier, size: VIconSize.md),
                        ],
                      ),
                      if (profession != null && profession!.isNotEmpty)
                        Text(
                          profession!,
                          style: const TextStyle(
                            fontSize: VFontSize.bodySm,
                            color: VCommuneColors.textMuted,
                          ),
                        ),
                      Text(
                        '${standing.title} · $rep rep',
                        style: const TextStyle(
                          fontSize: VFontSize.labelSm,
                          color: VCommuneColors.textMuted,
                        ),
                      ),
                      Text(
                        '$tierLabel tier',
                        style: const TextStyle(
                          fontSize: VFontSize.labelSm,
                          color: VCommuneColors.headerSecondary,
                          fontWeight: VFontWeight.semiBold,
                        ),
                      ),
                      if (customStatus != null &&
                          customStatus!.trim().isNotEmpty)
                        Text(
                          customStatus!.trim(),
                          style: const TextStyle(
                            fontSize: VFontSize.labelSm,
                            color: VCommuneColors.textMuted,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
                if (onDismiss != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: VIconSize.base),
                    onPressed: onDismiss,
                    tooltip: 'Close',
                  ),
              ],
            ),
            const SizedBox(height: VSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      onDismiss?.call();
                      context.push(residentProfilePath(residentId));
                    },
                    icon: const Icon(Icons.person_outline, size: VIconSize.base),
                    label: const Text('Profile'),
                  ),
                ),
                if (onMessage != null) ...[
                  const SizedBox(width: VSpacing.sm),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        onDismiss?.call();
                        onMessage!();
                      },
                      icon: const Icon(Icons.chat_bubble_outline, size: VIconSize.base),
                      label: const Text('Message'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

void showResidentMemberCard(
  BuildContext context, {
  required VMemberCard card,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(VSpacing.md),
        child: card,
      ),
    ),
  );
}
