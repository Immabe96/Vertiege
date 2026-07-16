import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../router/world_navigation.dart';
import 'package:vertiege/ui/ui.dart';
import '../../models/resident.dart';
import '../../models/world.dart';
import '../../services/access_control.dart';
import '../../services/admin_access_service.dart';
import '../../state/resident_provider.dart';
import '../../state/world_provider.dart';
import '../../theme/prestige_noir.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../../utils/provider_errors.dart';
import '../../utils/world_resident_count_label.dart';
import '../../widgets/core/empty_state.dart';
import '../../widgets/core/sync_warning_banner.dart';
import '../../widgets/core/v_accessible.dart';
import '../../widgets/explore/boosted_worlds_row.dart';
import '../../widgets/explore/shimmer_world_card.dart';
import '../../widgets/worlds/world_icon.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Map<String, bool> _expandedIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(worldProvider);
    final resident = ref.watch(residentProvider).resident;
    final theme = Theme.of(context);
    final worlds = state.worlds.values.toList();
    final isLoading = worlds.isEmpty && state.isLoading;

    final available = worlds.where((w) {
      if (resident == null) return true;
      return canAccessWorld(resident, w);
    }).toList();

    final locked = worlds.where((w) {
      if (resident == null) return false;
      return !canAccessWorld(resident, w);
    }).toList();

    final trending = available.where((w) => w.activityScore > 0).toList()
      ..sort((a, b) => b.activityScore.compareTo(a.activityScore));
    final topTrending = trending.take(5).toList();

    final boosted = List<World>.from(available)
      ..sort((a, b) => b.prestige.compareTo(a.prestige));
    // Featured should feel alive — skip empty shells even if prestige is high.
    final boostedWorlds = boosted
        .where((w) => w.prestige >= 10 && w.memberCount > 0)
        .take(5)
        .toList();
    final featuredIds = boostedWorlds.map((w) => w.id).toSet();

    final recommended = resident != null
        ? available
              .where(
                (w) =>
                    !featuredIds.contains(w.id) &&
                    !resident.joinedWorldIds.contains(w.id) &&
                    (w.requiredTier == null ||
                        resident.tier.value >= w.requiredTier!) &&
                    (w.requiredProfession == null ||
                        residentMatchesProfessionGate(
                          residentProfession: resident.profession,
                          verifiedRoles: resident.verifiedRoles,
                          requiredProfession: w.requiredProfession!,
                        )),
              )
              .take(8)
              .toList()
        : <World>[];

    List<World> filter(List<World> list) {
      if (_searchQuery.isEmpty) return list;
      final q = _searchQuery.toLowerCase();
      return list
          .where(
            (w) =>
                w.name.toLowerCase().contains(q) ||
                w.description.toLowerCase().contains(q) ||
                w.sovereignName.toLowerCase().contains(q),
          )
          .toList();
    }

    // Featured strip owns those worlds — don't repeat them in list sections.
    final filteredAvailable = filter(
      available
          .where(
            (w) =>
                !featuredIds.contains(w.id) &&
                !recommended.any((r) => r.id == w.id),
          )
          .toList(),
    );
    final filteredLocked = filter(
      locked.where((w) => !featuredIds.contains(w.id)).toList(),
    );
    final filteredRecommended = filter(recommended);
    final filteredTrending = filter(
      topTrending.where((w) => !featuredIds.contains(w.id)).toList(),
    );

    final headerActions = <Widget>[
      VAccessibleHeaderAction(
        label: 'Discover Worlds',
        icon: const Icon(VIcons.compass),
        onPress: () => context.push(exploreDiscoverPath()),
      ),
      if (AdminAccessService.canCreateWorld(
        tierValue: resident?.tier.value ?? 0,
      ))
        VAccessibleHeaderAction(
          label: 'Create World',
          icon: const Icon(VIcons.plus),
          onPress: () => context.push('/create-world'),
        ),
    ];

    return VTabPage(
      title: 'Worlds',
      headerActions: headerActions,
      body: isLoading
          ? CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(VSpacing.md),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, _) => const Padding(
                        padding: EdgeInsets.only(bottom: VSpacing.sm),
                        child: ShimmerWorldCard(),
                      ),
                      childCount: 6,
                    ),
                  ),
                ),
              ],
            )
          : RefreshIndicator(
              onRefresh: () => ref.read(worldProvider.notifier).loadWorlds(),
              child: CustomScrollView(
                slivers: [
                  if (state.loadError != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          VSpacing.md,
                          VSpacing.sm,
                          VSpacing.md,
                          0,
                        ),
                        child: worlds.isNotEmpty
                            ? SyncWarningBanner(
                                message: userFacingLoadError(
                                  state.loadError!,
                                  fallback: state.loadError!,
                                ),
                                onRetry: () => ref
                                    .read(worldProvider.notifier)
                                    .loadWorlds(),
                              )
                            : AppErrorState(
                                message: userFacingLoadError(
                                  state.loadError!,
                                  fallback: 'Could not load worlds.',
                                ),
                                onRetry: () => ref
                                    .read(worldProvider.notifier)
                                    .loadWorlds(),
                              ),
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        VSpacing.md,
                        VSpacing.sm,
                        VSpacing.md,
                        VSpacing.sm,
                      ),
                      child: Text(
                        'Join a world to submit proof, earn rep, and unlock channels.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                  if (boostedWorlds.isNotEmpty && _searchQuery.isEmpty)
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              VSpacing.md,
                              0,
                              VSpacing.md,
                              VSpacing.sm,
                            ),
                            child: Text(
                              'Featured worlds',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: VFontWeight.bold,
                                color: PrestigeNoir.foreground,
                              ),
                            ),
                          ),
                          BoostedWorldsRow(worlds: boostedWorlds),
                          const SizedBox(height: VSpacing.sm),
                        ],
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        VSpacing.md,
                        0,
                        VSpacing.md,
                        VSpacing.md,
                      ),
                      child: VSearchBar(
                        controller: _searchController,
                        hintText: 'Search worlds...',
                        onChanged: (v) => setState(() => _searchQuery = v),
                        onClear: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      ),
                    ),
                  ),

                  if (filteredTrending.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          VSpacing.md,
                          VSpacing.sm,
                          VSpacing.md,
                          VSpacing.sm,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.local_fire_department,
                              size: VIconSize.sm,
                              color: VColors.brand,
                            ),
                            const SizedBox(width: VSpacing.xs),
                            Text(
                              'Trending',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: VFontWeight.semiBold,
                                color: VColors.brand,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 140,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                            horizontal: VSpacing.md,
                          ),
                          itemCount: filteredTrending.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(width: VSpacing.sm),
                          itemBuilder: (context, index) {
                            final world = filteredTrending[index];
                            return _TrendingWorldCard(world: world);
                          },
                        ),
                      ),
                    ),
                  ],

                  if (filteredRecommended.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          VSpacing.md,
                          VSpacing.lg,
                          VSpacing.md,
                          VSpacing.sm,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              size: VIconSize.sm,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: VSpacing.xs),
                            Text(
                              'Recommended for You',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: VFontWeight.semiBold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: VSpacing.md,
                      ),
                      sliver: SliverList.separated(
                        itemCount: filteredRecommended.length > 3
                            ? 3
                            : filteredRecommended.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: VSpacing.sm),
                        itemBuilder: (context, index) => _WorldListCard(
                          world: filteredRecommended[index],
                          resident: resident,
                          isExpanded:
                              _expandedIds[filteredRecommended[index].id] ??
                              false,
                          onToggle: () {
                            setState(() {
                              _expandedIds[filteredRecommended[index].id] =
                                  !(_expandedIds[filteredRecommended[index]
                                          .id] ??
                                      false);
                            });
                          },
                        ),
                      ),
                    ),
                  ],

                  if (filteredAvailable.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          VSpacing.md,
                          VSpacing.sm,
                          VSpacing.md,
                          VSpacing.sm,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              size: VIconSize.sm,
                              color: VColors.success,
                            ),
                            const SizedBox(width: VSpacing.xs),
                            Text(
                              'Available (${filteredAvailable.length})',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: VFontWeight.semiBold,
                                color: VColors.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: VSpacing.md,
                      ),
                      sliver: SliverList.separated(
                        itemCount: filteredAvailable.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: VSpacing.sm),
                        itemBuilder: (context, index) => _WorldListCard(
                          world: filteredAvailable[index],
                          resident: resident,
                          isExpanded:
                              _expandedIds[filteredAvailable[index].id] ??
                              false,
                          onToggle: () {
                            setState(() {
                              _expandedIds[filteredAvailable[index].id] =
                                  !(_expandedIds[filteredAvailable[index].id] ??
                                      false);
                            });
                          },
                        ),
                      ),
                    ),
                  ],

                  if (filteredLocked.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          VSpacing.md,
                          VSpacing.lg,
                          VSpacing.md,
                          VSpacing.sm,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.lock_outline,
                              size: VIconSize.sm,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: VSpacing.xs),
                            Text(
                              'Locked (${filteredLocked.length})',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: VFontWeight.semiBold,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: VSpacing.md,
                      ),
                      sliver: SliverList.separated(
                        itemCount: filteredLocked.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: VSpacing.sm),
                        itemBuilder: (context, index) => _WorldListCard(
                          world: filteredLocked[index],
                          resident: resident,
                          isLocked: true,
                          isExpanded:
                              _expandedIds[filteredLocked[index].id] ?? false,
                          onToggle: () {
                            setState(() {
                              _expandedIds[filteredLocked[index].id] =
                                  !(_expandedIds[filteredLocked[index].id] ??
                                      false);
                            });
                          },
                        ),
                      ),
                    ),
                  ],

                  if (filteredAvailable.isEmpty && filteredLocked.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(VSpacing.xxl),
                        child: AppEmptyState(
                          title: _searchQuery.isNotEmpty
                              ? 'No worlds found'
                              : 'Find your first world',
                          description: _searchQuery.isNotEmpty
                              ? 'No worlds match "$_searchQuery". Try another search or browse Discover.'
                              : 'Join a world to unlock Chat channels, then submit proof to earn XP.',
                          icon: _searchQuery.isNotEmpty
                              ? Icons.search_off
                              : Icons.public,
                          illustration: EmptyStateIllustration.worlds,
                          actionLabel: _searchQuery.isNotEmpty
                              ? 'Clear search'
                              : 'Discover worlds',
                          onAction: _searchQuery.isNotEmpty
                              ? () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                }
                              : () => context.push(exploreDiscoverPath()),
                          secondaryActionLabel: _searchQuery.isEmpty
                              ? 'Submit proof'
                              : null,
                          onSecondaryAction: _searchQuery.isEmpty
                              ? () => context.push('/achievements/submit')
                              : null,
                        ),
                      ),
                    ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: VSpacing.xxl + VSpacing.xl),
                  ),
                ],
              ),
            ),
    );
  }
}

class _WorldListCard extends StatelessWidget {
  final World world;
  final Resident? resident;
  final bool isLocked;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _WorldListCard({
    required this.world,
    required this.resident,
    this.isLocked = false,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final typeColor = _typeColor(world.type);
    final typeLabel = _typeLabel(world.type);
    final lockReason = _lockReason(world, resident);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        // Row expands details; Enter World navigates (avoids chevron vs open conflict).
        onTap: isLocked ? null : onToggle,
        borderRadius: BorderRadius.circular(VRadius.bento),
        child: VPrestigeCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(VSpacing.md),
                child: Row(
                  children: [
                    WorldIcon(
                      worldId: world.assetKey.isNotEmpty
                          ? world.assetKey
                          : world.id,
                      size: VWorldIconSize.list,
                      useGlassContainer: false,
                    ),
                    const SizedBox(width: VSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  world.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: VFontWeight.semiBold,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              if (isLocked)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: VSpacing.xs,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: VColors.error.withValues(
                                      alpha: 0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      VRadius.pill,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.lock,
                                        size: VIconSize.xs,
                                        color: VColors.error,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        'Locked',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              color: VColors.error,
                                              fontWeight: VFontWeight.semiBold,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: VSpacing.xs,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: typeColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(
                                    VRadius.pill,
                                  ),
                                ),
                                child: Text(
                                  typeLabel,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: typeColor,
                                    fontWeight: VFontWeight.semiBold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: VSpacing.xs),
                              Text(
                                worldMemberCountLabel(world.memberCount),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(width: VSpacing.xs),
                              Text(
                                'P${world.prestige}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: VSpacing.sm),
                    Tooltip(
                      message: isExpanded ? 'Collapse' : 'Show details',
                      child: AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0,
                        duration: VAnimation.fast,
                        child: Icon(
                          Icons.expand_more,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (isExpanded) ...[
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(VSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        world.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: VSpacing.md),
                      Wrap(
                        spacing: VSpacing.xs,
                        runSpacing: VSpacing.xs,
                        children: [
                          _InfoChip(
                            icon: Icons.person,
                            label: world.sovereignStatusLabel,
                          ),
                          if (world.requiredTier != null)
                            _InfoChip(
                              icon: Icons.star,
                              label: 'Requires Tier ${world.requiredTier}',
                            ),
                          if (world.requiredProfession != null)
                            _InfoChip(
                              icon: Icons.work,
                              label: 'Requires: ${world.requiredProfession}',
                            ),
                          if (world.constitution.admission != 'open')
                            _InfoChip(
                              icon: Icons.description,
                              label:
                                  'Admission: ${world.constitution.admission}',
                            ),
                        ],
                      ),
                      if (isLocked && lockReason != null) ...[
                        const SizedBox(height: VSpacing.md),
                        Container(
                          padding: const EdgeInsets.all(VSpacing.sm),
                          decoration: BoxDecoration(
                            color: VColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(VRadius.md),
                            border: Border.all(
                              color: VColors.error.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                size: VIconSize.sm,
                                color: VColors.error,
                              ),
                              const SizedBox(width: VSpacing.sm),
                              Expanded(
                                child: Text(
                                  lockReason,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: VColors.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (!isLocked) ...[
                        const SizedBox(height: VSpacing.md),
                        VButton(
                          label: 'Enter World',
                          icon: const Icon(VIcons.arrowLeft),
                          isFullWidth: true,
                          onPressed: () =>
                              context.push(exploreWorldPath(world.id)),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String? _lockReason(World world, Resident? resident) {
    if (resident == null) return null;
    switch (world.type) {
      case WorldType.wealth:
        final req = world.requiredTier ?? 1;
        if (resident.tier.value < req &&
            !resident.wealthWorldsUnlocked.contains(world.id)) {
          return 'Reach Tier $req or unlock this world to enter.';
        }
        break;
      case WorldType.profession:
        final req = world.requiredProfession;
        if (req != null && !resident.verifiedRoles.contains(req)) {
          return 'Verify your $req profession to access this world.';
        }
        break;
      case WorldType.dominion:
        break;
    }
    return null;
  }

  Color _typeColor(WorldType type) {
    return switch (type) {
      WorldType.wealth => VColors.brand,
      WorldType.profession => VColors.secondary,
      WorldType.dominion => VColors.success,
    };
  }

  String _typeLabel(WorldType type) {
    return switch (type) {
      WorldType.wealth => 'Wealth',
      WorldType.profession => 'Profession',
      WorldType.dominion => 'Dominion',
    };
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.sm,
        vertical: VSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: PrestigeNoir.surfaceRaised,
        borderRadius: BorderRadius.circular(VRadius.pill),
        border: Border.all(color: PrestigeNoir.borderLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: VIconSize.xs,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: VSpacing.xxs),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendingWorldCard extends StatelessWidget {
  final World world;

  const _TrendingWorldCard({required this.world});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => context.push(exploreWorldPath(world.id)),
      child: SizedBox(
        width: 160,
        child: VPrestigeCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.local_fire_department,
                    size: VIconSize.sm,
                    color: VColors.brand,
                  ),
                  const SizedBox(width: VSpacing.xxs),
                  Text(
                    '${world.activityScore}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: VColors.brand,
                      fontWeight: VFontWeight.semiBold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: VSpacing.xs),
              Text(
                world.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: VFontWeight.semiBold,
                  color: PrestigeNoir.foreground,
                ),
              ),
              const Spacer(),
              Text(
                worldMemberCountLabel(world.memberCount),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: PrestigeNoir.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
