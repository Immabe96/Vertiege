import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vertiege/ui/ui.dart';

import '../../config/tiers.dart';
import '../../config/world_capability_matrix.dart';
import '../../models/channel.dart';
import '../../models/post.dart';
import '../../models/resident.dart';
import '../../models/world.dart';
import '../../models/poll.dart';
import '../../services/analytics_events.dart';
import '../../services/analytics_service.dart';
import '../../services/feature_flags.dart';
import '../../services/poll_service.dart';
import '../../router/world_navigation.dart';
import '../../state/world_provider.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../../utils/world_foundations.dart';
import 'alliance_section.dart';
import 'resource_vault.dart';
import 'world_growth_card.dart';
import 'world_member_row.dart';
import 'dossier_collapsible_section.dart';
import 'world_constitution_sheet.dart';

/// G4 realm dossier — About tab content (Forui sections).
class WorldRealmDossier extends ConsumerStatefulWidget {
  final World world;
  final String worldId;
  final List<WorldChannel> channels;
  final List<Post> worldPosts;
  final Resident? resident;
  final bool isJoined;
  final bool isSovereignOrCouncil;
  final VoidCallback onJoin;
  final VoidCallback? onSettings;
  final VoidCallback onShare;
  final ValueChanged<String> onOpenChannel;
  final List<WorldMemberEntry> members;
  final bool membersLoading;

  const WorldRealmDossier({
    super.key,
    required this.world,
    required this.worldId,
    required this.channels,
    required this.worldPosts,
    required this.resident,
    required this.isJoined,
    required this.isSovereignOrCouncil,
    required this.onJoin,
    this.onSettings,
    required this.onShare,
    required this.onOpenChannel,
    this.members = const [],
    this.membersLoading = false,
  });

  @override
  ConsumerState<WorldRealmDossier> createState() => _WorldRealmDossierState();
}

class _WorldRealmDossierState extends ConsumerState<WorldRealmDossier> {
  bool _loggedView = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _logViewedOnce());
  }

  void _logViewedOnce() {
    if (_loggedView) return;
    _loggedView = true;
    AnalyticsService.logEvent(
      AnalyticsEvents.worldDossierViewed,
      parameters: {
        'world_id': widget.worldId,
        'is_joined': widget.isJoined ? '1' : '0',
        'world_type': widget.world.type.name,
      },
    );
  }

  void _logTile(String event, {String? tile}) {
    AnalyticsService.logEvent(
      event,
      parameters: {
        'world_id': widget.worldId,
        if (tile != null) 'tile': tile,
      },
    );
  }

  List<Post> get _newsPosts {
    final sovereignId = widget.world.sovereignId;
    return widget.worldPosts
        .where(
          (p) =>
              p.status == 'published' &&
              (p.isAnnouncement ||
                  p.isDecree ||
                  p.residentId == sovereignId),
        )
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  WorldChannel? get _infoChannel {
    for (final c in widget.channels) {
      final n = c.name.toLowerCase();
      if (n == 'info' || n == 'information') return c;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final foundation = foundationForWorld(widget.world);
    final features = ref.read(worldProvider.notifier).featuresForWorld(widget.worldId);
    final news = _newsPosts.take(3).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        VSpacing.md,
        VSpacing.sm,
        VSpacing.md,
        VSpacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TypeLeadSection(world: widget.world),
          const SizedBox(height: VSpacing.md),
          _CharterSection(
            world: widget.world,
            foundation: foundation,
            isJoined: widget.isJoined,
            isDark: isDark,
            onJoin: () {
              _logTile(AnalyticsEvents.worldDossierCharterCta);
              widget.onJoin();
            },
          ),
          if (foundation.safetyDisclaimer != null &&
              foundation.safetyDisclaimer!.trim().isNotEmpty) ...[
            const SizedBox(height: VSpacing.md),
            _SafetyDisclaimerSection(
              disclaimer: foundation.safetyDisclaimer!.trim(),
              isDark: isDark,
            ),
          ],
          const SizedBox(height: VSpacing.md),
          _StandingSection(
            world: widget.world,
            worldId: widget.worldId,
            resident: widget.resident,
            isJoined: widget.isJoined,
            isDark: isDark,
          ),
          const SizedBox(height: VSpacing.md),
          _EconomySection(
            world: widget.world,
            worldId: widget.worldId,
            resident: widget.resident,
            isJoined: widget.isJoined,
            isSovereignOrCouncil: widget.isSovereignOrCouncil,
            features: features,
            onLogTile: _logTile,
          ),
          const SizedBox(height: VSpacing.md),
          DossierCollapsibleSection(
            title: 'Knowledge',
            child: _KnowledgeSection(
              infoChannel: _infoChannel,
              onOpenChannel: (name) {
                _logTile(AnalyticsEvents.worldDossierKnowledgeLink);
                widget.onOpenChannel(name);
              },
            ),
          ),
          const SizedBox(height: VSpacing.md),
          DossierCollapsibleSection(
            title: 'News & decrees',
            initiallyExpanded: news.isNotEmpty,
            child: _NewsSection(
              posts: news,
              isDark: isDark,
              onOpenPost: (postId) {
                _logTile(
                  AnalyticsEvents.worldDossierNewsOpen,
                  tile: postId,
                );
                context.push(
                  exploreWorldPath(widget.worldId, postId: postId),
                );
              },
            ),
          ),
          const SizedBox(height: VSpacing.md),
          DossierCollapsibleSection(
            title: 'Get started',
            child: _OrientationSection(
              world: widget.world,
              onOpenChannel: (channel) {
                _logTile(
                  AnalyticsEvents.worldDossierOrientationStep,
                  tile: channel,
                );
                widget.onOpenChannel(channel);
              },
            ),
          ),
          const SizedBox(height: VSpacing.md),
          _CouncilPreviewSection(
            world: widget.world,
            worldId: widget.worldId,
            members: widget.members,
            membersLoading: widget.membersLoading,
            onLog: _logTile,
          ),
          const SizedBox(height: VSpacing.md),
          _GovernanceSection(
            worldId: widget.worldId,
            isJoined: widget.isJoined,
            isSovereignOrCouncil: widget.isSovereignOrCouncil,
            onSettings: widget.onSettings,
            onLog: _logTile,
          ),
          const SizedBox(height: VSpacing.md),
          ResourceVault(
            worldId: widget.worldId,
            channels: widget.channels,
            vaultUnlocked: features.vault,
          ),
          const SizedBox(height: VSpacing.md),
          AllianceSection(worldId: widget.worldId, world: widget.world),
          const SizedBox(height: VSpacing.md),
          VSectionList(
            title: 'Quick links',
            children: [
              VSectionTile(
                icon: Icons.share_outlined,
                label: 'Share world',
                onTap: widget.onShare,
              ),
              if (widget.isJoined) ...[
                VSectionTile(
                  icon: Icons.menu_book_outlined,
                  label: 'World archive',
                  onTap: () => context.push(worldArchivePath(widget.worldId)),
                ),
                VSectionTile(
                  icon: Icons.people_outline,
                  label: 'Full resident roster',
                  onTap: () => context.push(
                    worldMembersPath(
                      widget.worldId,
                      worldName: widget.world.name,
                      sovereignId: widget.world.sovereignId,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _TypeLeadSection extends StatelessWidget {
  final World world;

  const _TypeLeadSection({required this.world});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (world.type == WorldType.dominion) {
      return WorldGrowthCard(world: world);
    }

    final access = world.requiredProfession != null
        ? 'Verified ${world.requiredProfession}'
        : 'Tier ${world.requiredTier ?? 1} · ${tierNames[world.requiredTier ?? 1] ?? 'Open'}';

    return VSurfaceCard(
      child: Padding(
        padding: const EdgeInsets.all(VSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  world.type == WorldType.profession
                      ? Icons.badge_outlined
                      : Icons.diamond_outlined,
                  color: VColors.primary,
                  size: VIconSize.md,
                ),
                const SizedBox(width: VSpacing.sm),
                Text(
                  world.type == WorldType.profession
                      ? 'Profession realm'
                      : 'Wealth realm',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: VFontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: VSpacing.sm),
            Text(
              access,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: VColors.primary,
                fontWeight: VFontWeight.semiBold,
              ),
            ),
            const SizedBox(height: VSpacing.xs),
            Text(
              'Prestige ${world.prestige} · ${world.sovereignStatusLabel}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? VColors.onSurfaceVariantDark
                    : VColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CharterSection extends StatelessWidget {
  final World world;
  final WorldFoundation foundation;
  final bool isJoined;
  final bool isDark;
  final VoidCallback onJoin;

  const _CharterSection({
    required this.world,
    required this.foundation,
    required this.isJoined,
    required this.isDark,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final access = world.requiredProfession != null
        ? 'Verified ${world.requiredProfession} residents'
        : 'Tier ${world.requiredTier ?? 1} ${tierNames[world.requiredTier ?? 1] ?? ''}';

    return VSurfaceCard(
      child: Padding(
        padding: const EdgeInsets.all(VSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Charter',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: VFontWeight.bold,
              ),
            ),
            const SizedBox(height: VSpacing.sm),
            Text(
              isJoined ? foundation.premise : _teaserPremise(world, foundation),
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.35,
                color: isDark ? VColors.onSurfaceDark : VColors.onSurface,
              ),
            ),
            const SizedBox(height: VSpacing.sm),
            Text(
              'Access: $access',
              style: theme.textTheme.labelMedium?.copyWith(
                color: VColors.primary,
                fontWeight: VFontWeight.semiBold,
              ),
            ),
            if (isJoined) ...[
              const SizedBox(height: VSpacing.md),
              _BulletBlock(title: 'Focus', items: foundation.focus),
              const SizedBox(height: VSpacing.sm),
              _BulletBlock(title: 'Culture', items: foundation.culture),
            ] else ...[
              const SizedBox(height: VSpacing.md),
              OutlinedButton(
                onPressed: () {
                  showWorldConstitutionPreview(context, world: world);
                },
                child: const Text('Preview charter'),
              ),
              const SizedBox(height: VSpacing.sm),
              VButton(
                label: 'Join to read the full charter',
                onPressed: onJoin,
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _teaserPremise(World world, WorldFoundation foundation) {
    final raw = world.description.isNotEmpty
        ? world.description
        : foundation.premise;
    if (raw.length <= 220) return raw;
    return '${raw.substring(0, 217).trim()}…';
  }
}

class _SafetyDisclaimerSection extends StatelessWidget {
  final String disclaimer;
  final bool isDark;

  const _SafetyDisclaimerSection({
    required this.disclaimer,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return VSurfaceCard(
      child: Padding(
        padding: const EdgeInsets.all(VSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.health_and_safety_outlined,
              color: VColors.warning,
              size: VIconSize.md,
            ),
            const SizedBox(width: VSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Safety disclaimer',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: VFontWeight.semiBold,
                      color: VColors.warning,
                    ),
                  ),
                  const SizedBox(height: VSpacing.xs),
                  Text(
                    disclaimer,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? VColors.onSurfaceVariantDark
                          : VColors.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BulletBlock extends StatelessWidget {
  final String title;
  final List<String> items;

  const _BulletBlock({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: VFontWeight.semiBold,
          ),
        ),
        const SizedBox(height: VSpacing.xs),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: VSpacing.xxs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• '),
                Expanded(child: Text(item, style: theme.textTheme.bodySmall)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StandingSection extends StatelessWidget {
  final World world;
  final String worldId;
  final Resident? resident;
  final bool isJoined;
  final bool isDark;

  const _StandingSection({
    required this.world,
    required this.worldId,
    required this.resident,
    required this.isJoined,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rep = isJoined && resident != null
        ? (resident!.worldStandings[worldId]?.rep ?? 0)
        : null;
    final current = rep != null ? getStanding(rep) : null;

    return VSurfaceCard(
      child: Padding(
        padding: const EdgeInsets.all(VSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Standing',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: VFontWeight.bold,
              ),
            ),
            if (isJoined && current != null) ...[
              const SizedBox(height: VSpacing.sm),
              Text(
                'You are ${current.title} · $rep rep',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: VColors.tertiary,
                  fontWeight: VFontWeight.semiBold,
                ),
              ),
            ] else ...[
              const SizedBox(height: VSpacing.sm),
              Text(
                'Join and participate to earn rep in this world.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? VColors.onSurfaceVariantDark
                      : VColors.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: VSpacing.md),
            ...standingLevels.map((level) {
              final active = current?.level == level.level;
              return Padding(
                padding: const EdgeInsets.only(bottom: VSpacing.xs),
                child: Row(
                  children: [
                    Icon(
                      active ? Icons.check_circle : Icons.circle_outlined,
                      size: 16,
                      color: active ? VColors.success : VColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: VSpacing.xs),
                    Expanded(
                      child: Text(
                        '${level.title} · ${level.minRep}+ rep',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight:
                              active ? VFontWeight.semiBold : VFontWeight.regular,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _EconomySection extends StatelessWidget {
  final World world;
  final String worldId;
  final Resident? resident;
  final bool isJoined;
  final bool isSovereignOrCouncil;
  final WorldFeatures features;
  final void Function(String event, {String? tile}) onLogTile;

  const _EconomySection({
    required this.world,
    required this.worldId,
    required this.resident,
    required this.isJoined,
    required this.isSovereignOrCouncil,
    required this.features,
    required this.onLogTile,
  });

  @override
  Widget build(BuildContext context) {
    final showMarket = FeatureFlags.marketplace &&
        WorldCapabilityMatrix.worldHasMarketplace(world);
    final showTreasury = FeatureFlags.treasury &&
        WorldCapabilityMatrix.worldHasTreasury(world);
    final showPolls = FeatureFlags.polls && isJoined;
    final showChallenges = FeatureFlags.challenges && isJoined;

    if (!showMarket && !showTreasury && !showPolls && !showChallenges) {
      return const SizedBox.shrink();
    }

    final canTreasuryAdmin =
        WorldCapabilityMatrix.canManageTreasury(resident, world);
    final canList = WorldCapabilityMatrix.canCreateListing(
      resident,
      world,
      isJoined: isJoined,
    );

    final tiles = <VSectionTile>[];
    if (showTreasury) {
      tiles.add(_economyTile(
        context,
        icon: Icons.account_balance_wallet,
        label: 'Treasury',
        enabled: isJoined &&
            WorldCapabilityMatrix.canDonateTreasury(
              resident,
              world,
              isJoined: isJoined,
            ),
        lockReason: WorldCapabilityMatrix.blockReasonTreasuryDonate(
          resident,
          world,
          isJoined: isJoined,
        ),
        onTap: () {
          onLogTile(AnalyticsEvents.worldDossierEconomyTile, tile: 'treasury');
          context.push(
            worldTreasuryPath(worldId, admin: canTreasuryAdmin),
          );
        },
      ));
    }
    if (showMarket) {
      final listBlock = WorldCapabilityMatrix.blockReasonCreateListing(
        resident,
        world,
        isJoined: isJoined,
      );
      tiles.add(_economyTile(
        context,
        icon: Icons.storefront,
        label: 'Marketplace',
        enabled: true,
        showLock: !canList,
        lockReason: listBlock,
        onTap: () {
          onLogTile(AnalyticsEvents.worldDossierEconomyTile, tile: 'marketplace');
          context.push(
            worldMarketplacePath(
              worldId,
              member: isJoined && canList,
            ),
          );
        },
      ));
    }
    if (showPolls) {
      tiles.add(_economyTile(
        context,
        icon: Icons.how_to_vote,
        label: 'Polls',
        enabled: isJoined,
        lockReason: isJoined ? null : 'Join this world to vote.',
        onTap: () {
          onLogTile(AnalyticsEvents.worldDossierEconomyTile, tile: 'polls');
          context.push(
            worldPollsPath(worldId, admin: isSovereignOrCouncil),
          );
        },
      ));
    }
    if (showChallenges) {
      tiles.add(_economyTile(
        context,
        icon: Icons.emoji_events,
        label: 'World challenges',
        enabled: isJoined,
        lockReason: isJoined ? null : 'Join this world to compete.',
        onTap: () {
          onLogTile(AnalyticsEvents.worldDossierEconomyTile, tile: 'challenges');
          context.push(worldChallengesPath(worldId));
        },
      ));
    }
    if (isJoined) {
      tiles.add(_economyTile(
        context,
        icon: Icons.work_outline,
        label: 'Role board',
        enabled: true,
        lockReason: null,
        onTap: () {
          onLogTile(AnalyticsEvents.worldDossierEconomyTile, tile: 'jobs');
          context.push(
            worldJobsPath(worldId, admin: isSovereignOrCouncil),
          );
        },
      ));
    }

    if (tiles.isEmpty) return const SizedBox.shrink();

    return VSectionList(title: 'Economy', children: tiles);
  }

  static VSectionTile _economyTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool enabled,
    bool showLock = false,
    required String? lockReason,
    required VoidCallback onTap,
  }) {
    return VSectionTile(
      icon: icon,
      label: label,
      enabled: enabled,
      titleColor: enabled ? null : VColors.onSurfaceVariant,
      trailing: (!enabled || showLock)
          ? const Icon(Icons.lock_outline, size: 18)
          : null,
      onTap: enabled
          ? () {
              if (showLock && lockReason != null) {
                VFeedback.showMessage(context, lockReason);
              }
              onTap();
            }
          : () {
              if (lockReason != null) {
                VFeedback.showMessage(context, lockReason);
              }
            },
    );
  }
}

class _KnowledgeSection extends StatelessWidget {
  final WorldChannel? infoChannel;
  final ValueChanged<String> onOpenChannel;

  const _KnowledgeSection({
    required this.infoChannel,
    required this.onOpenChannel,
  });

  @override
  Widget build(BuildContext context) {
    if (infoChannel == null) {
      return Text(
        'Knowledge channels are being prepared.',
        style: Theme.of(context).textTheme.bodySmall,
      );
    }

    return VSectionTile(
      icon: Icons.menu_book_outlined,
      label: 'Read charter in #${infoChannel!.name}',
      onTap: () => onOpenChannel(infoChannel!.name),
    );
  }
}

class _NewsSection extends StatelessWidget {
  final List<Post> posts;
  final bool isDark;
  final ValueChanged<String> onOpenPost;

  const _NewsSection({
    required this.posts,
    required this.isDark,
    required this.onOpenPost,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (posts.isEmpty)
              Text(
                'No announcements yet. Check back when the sovereign posts.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? VColors.onSurfaceVariantDark
                      : VColors.onSurfaceVariant,
                ),
              )
            else
              ...posts.map((post) {
                final preview = post.content.length > 120
                    ? '${post.content.substring(0, 117)}…'
                    : post.content;
                return Padding(
                  padding: const EdgeInsets.only(bottom: VSpacing.sm),
                  child: InkWell(
                    onTap: () => onOpenPost(post.id),
                    borderRadius: BorderRadius.circular(VRadius.md),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: VSpacing.xs,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.isDecree
                                ? 'Decree · ${post.residentName}'
                                : post.isAnnouncement
                                ? 'Announcement · ${post.residentName}'
                                : post.residentName,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: VColors.primary,
                              fontWeight: VFontWeight.semiBold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            preview,
                            style: theme.textTheme.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
      ],
    );
  }
}

class _OrientationSection extends StatelessWidget {
  final World world;
  final ValueChanged<String> onOpenChannel;

  const _OrientationSection({
    required this.world,
    required this.onOpenChannel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final steps = orientationStepsForWorld(world);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...steps.asMap().entries.map((entry) {
              final i = entry.key;
              final step = entry.value;
              return Padding(
                padding: EdgeInsets.only(
                  bottom: i < steps.length - 1 ? VSpacing.sm : 0,
                ),
                child: InkWell(
                  onTap: () => onOpenChannel(step.channel),
                  borderRadius: BorderRadius.circular(VRadius.md),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: VSpacing.xs,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: VColors.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${i + 1}',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: VColors.primary,
                              fontWeight: VFontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: VSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                step.title,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: VFontWeight.semiBold,
                                ),
                              ),
                              Text(
                                step.description,
                                style: theme.textTheme.bodySmall,
                              ),
                              Text(
                                'Open #${step.channel}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: VColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          VIcons.chevronRight,
                          size: 18,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
              );
        }),
      ],
    );
  }
}

class _CouncilPreviewSection extends StatelessWidget {
  final World world;
  final String worldId;
  final List<WorldMemberEntry> members;
  final bool membersLoading;
  final void Function(String event, {String? tile}) onLog;

  const _CouncilPreviewSection({
    required this.world,
    required this.worldId,
    required this.members,
    required this.membersLoading,
    required this.onLog,
  });

  static const _councilRepMin = 5000;

  List<WorldMemberEntry> _leaders() {
    final sovereignId = world.sovereignId;
    final out = <WorldMemberEntry>[];
    final sovereign = members
        .where((m) => m.resident.id == sovereignId)
        .firstOrNull;
    if (sovereign != null) out.add(sovereign);
    final council = members
        .where((m) => m.rep >= _councilRepMin && m.resident.id != sovereignId)
        .toList()
      ..sort((a, b) => b.rep.compareTo(a.rep));
    for (final m in council) {
      if (out.length >= 6) break;
      out.add(m);
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final leaders = _leaders();

    return VSurfaceCard(
      child: Padding(
        padding: const EdgeInsets.all(VSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Leadership',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: VFontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => context.push(
                    worldMembersPath(
                      worldId,
                      worldName: world.name,
                      sovereignId: world.sovereignId,
                    ),
                  ),
                  child: const Text('Full roster'),
                ),
              ],
            ),
            const SizedBox(height: VSpacing.sm),
            if (membersLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(VSpacing.lg),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else if (leaders.isEmpty)
              Text(
                'Council members will appear here once residents reach '
                '$_councilRepMin rep.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? VColors.onSurfaceVariantDark
                      : VColors.onSurfaceVariant,
                ),
              )
            else
              ...leaders.map((entry) {
                final isSovereign = entry.resident.id == world.sovereignId;
                final standing = getStanding(entry.rep);
                return Padding(
                  padding: const EdgeInsets.only(bottom: VSpacing.sm),
                  child: InkWell(
                    onTap: () {
                      onLog(
                        AnalyticsEvents.worldDossierCouncilTap,
                        tile: entry.resident.id,
                      );
                      context.push(residentProfilePath(entry.resident.id));
                    },
                    borderRadius: BorderRadius.circular(VRadius.md),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: VSpacing.xs,
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundImage:
                                entry.resident.avatarUrl.isNotEmpty
                                ? NetworkImage(entry.resident.avatarUrl)
                                : null,
                            child: entry.resident.avatarUrl.isEmpty
                                ? Text(
                                    entry.resident.name.isNotEmpty
                                        ? entry.resident.name[0]
                                        : '?',
                                  )
                                : null,
                          ),
                          const SizedBox(width: VSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.resident.name,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: VFontWeight.semiBold,
                                  ),
                                ),
                                Text(
                                  isSovereign
                                      ? 'Sovereign'
                                      : '${standing.title} · ${entry.rep} rep',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: isSovereign
                                        ? VColors.tertiary
                                        : VColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            VIcons.chevronRight,
                            size: 18,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _GovernanceSection extends StatefulWidget {
  final String worldId;
  final bool isJoined;
  final bool isSovereignOrCouncil;
  final VoidCallback? onSettings;
  final void Function(String event, {String? tile}) onLog;

  const _GovernanceSection({
    required this.worldId,
    required this.isJoined,
    required this.isSovereignOrCouncil,
    required this.onSettings,
    required this.onLog,
  });

  @override
  State<_GovernanceSection> createState() => _GovernanceSectionState();
}

class _GovernanceSectionState extends State<_GovernanceSection> {
  WorldPoll? _activePoll;
  bool _pollLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPoll();
  }

  Future<void> _loadPoll() async {
    if (!FeatureFlags.polls || !widget.isJoined) {
      if (mounted) setState(() => _pollLoading = false);
      return;
    }
    try {
      final polls = await PollService.getPolls(
        widget.worldId,
        activeOnly: true,
        limit: 1,
      );
      if (!mounted) return;
      setState(() {
        _activePoll = polls.isNotEmpty ? polls.first : null;
        _pollLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _pollLoading = false);
    }
  }

  void _openPolls() {
    widget.onLog(AnalyticsEvents.worldDossierGovernanceTap, tile: 'polls');
    context.push(
      worldPollsPath(
        widget.worldId,
        admin: widget.isSovereignOrCouncil,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final showPolls = FeatureFlags.polls;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showPolls && widget.isJoined) ...[
          if (_pollLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: VSpacing.sm),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (_activePoll != null)
            VSurfaceCard(
              child: Padding(
                padding: const EdgeInsets.all(VSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Active poll',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: VColors.primary,
                        fontWeight: VFontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: VSpacing.xs),
                    Text(
                      _activePoll!.question,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: VFontWeight.semiBold,
                      ),
                    ),
                    const SizedBox(height: VSpacing.sm),
                    ..._activePoll!.options.asMap().entries.map((e) {
                      final votes = _activePoll!.results[e.key] ?? 0;
                      final total = _activePoll!.totalVotes;
                      final pct = total > 0 ? votes / total : 0.0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: VSpacing.xs),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e.value,
                              style: theme.textTheme.bodySmall,
                            ),
                            const SizedBox(height: 2),
                            LinearProgressIndicator(
                              value: total > 0 ? pct : 0,
                              minHeight: 4,
                              borderRadius: BorderRadius.circular(VRadius.pill),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: VSpacing.sm),
                    TextButton(
                      onPressed: _openPolls,
                      child: const Text('Vote or view all polls'),
                    ),
                  ],
                ),
              ),
            )
          else
            VAlert(
              icon: Icon(VIcons.info),
              title: const Text('Governance voting'),
              subtitle: Text(
                'No active polls. Council and sovereign can create votes when needed.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? VColors.onSurfaceVariantDark
                      : VColors.onSurfaceVariant,
                ),
              ),
            ),
          const SizedBox(height: VSpacing.sm),
          VSectionList(
            title: 'Governance',
            children: [
              VSectionTile(
                icon: Icons.how_to_vote,
                label: 'Open polls',
                onTap: _openPolls,
              ),
            ],
          ),
        ] else
          VAlert(
            icon: Icon(VIcons.info),
            title: const Text('Governance voting'),
            subtitle: Text(
              widget.isJoined
                  ? 'Polls unlock when governance is enabled for this world.'
                  : 'Join this world to participate in council polls.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? VColors.onSurfaceVariantDark
                    : VColors.onSurfaceVariant,
              ),
            ),
          ),
        if (widget.onSettings != null) ...[
          const SizedBox(height: VSpacing.sm),
          VSectionList(
            title: 'Leadership',
            children: [
              VSectionTile(
                icon: Icons.settings,
                label: 'World settings',
                onTap: () {
                  widget.onLog(AnalyticsEvents.worldDossierGovernanceTap);
                  widget.onSettings!();
                },
              ),
            ],
          ),
        ],
      ],
    );
  }
}
