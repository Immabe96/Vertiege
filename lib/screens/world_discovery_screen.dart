import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../router/world_navigation.dart';
import '../../models/world.dart';
import '../../services/access_control.dart';
import '../../services/admin_access_service.dart';
import '../../services/world_service.dart';
import '../../state/resident_provider.dart';
import '../../theme/prestige_noir.dart';
import '../../theme/v_tokens.dart';
import '../../widgets/core/shimmer.dart';
import '../../widgets/worlds/world_banner.dart';
import 'package:vertiege/ui/ui.dart';

class WorldDiscoveryScreen extends ConsumerStatefulWidget {
  /// When true, omits [VHubPage] chrome — used as Home slide-over (DCX-024).
  final bool embedded;
  final VoidCallback? onClose;

  const WorldDiscoveryScreen({
    super.key,
    this.embedded = false,
    this.onClose,
  });

  @override
  ConsumerState<WorldDiscoveryScreen> createState() =>
      _WorldDiscoveryScreenState();
}

class _WorldDiscoveryScreenState extends ConsumerState<WorldDiscoveryScreen> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _worlds = [];
  List<Map<String, dynamic>> _trending = [];
  List<Map<String, dynamic>> _featured = [];
  bool _loading = true;
  String? _selectedType;
  String? _selectedDominionType;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _loadData();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), _loadData);
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final futures = await Future.wait([
        WorldService.searchWorlds(
          query: _searchController.text.isEmpty ? null : _searchController.text,
          type: _selectedType,
          dominionType: _selectedDominionType,
        ),
        WorldService.getTrendingWorlds(),
        WorldService.getFeaturedWorlds(),
      ]);
      if (mounted) {
        setState(() {
          _worlds = futures[0];
          _trending = futures[1];
          _featured = futures[2];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final resident = ref.watch(residentProvider).resident;
    final canCreateWorld = AdminAccessService.canCreateWorld(
      tierValue: resident?.tier.value ?? 0,
    );

    final body = Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            VSpacing.md,
            VSpacing.md,
            VSpacing.md,
            VSpacing.sm,
          ),
          child: _DiscoverySearchPill(
            controller: _searchController,
            onChanged: _onSearchChanged,
            onClear: () {
              _searchController.clear();
              _loadData();
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: VSpacing.md),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _PrestigeFilterChip(
                  label: 'All Types',
                  selected: _selectedType == null,
                  onTap: () => setState(() {
                    _selectedType = null;
                    _selectedDominionType = null;
                    _loadData();
                  }),
                ),
                const SizedBox(width: 6),
                _PrestigeFilterChip(
                  label: 'Wealth',
                  selected: _selectedType == 'wealth',
                  onTap: () => setState(() {
                    _selectedType = 'wealth';
                    _selectedDominionType = null;
                    _loadData();
                  }),
                ),
                const SizedBox(width: 6),
                _PrestigeFilterChip(
                  label: 'Profession',
                  selected: _selectedType == 'profession',
                  onTap: () => setState(() {
                    _selectedType = 'profession';
                    _selectedDominionType = null;
                    _loadData();
                  }),
                ),
                const SizedBox(width: 6),
                _PrestigeFilterChip(
                  label: 'Dominion',
                  selected: _selectedType == 'dominion',
                  onTap: () => setState(() {
                    _selectedType = 'dominion';
                    _loadData();
                  }),
                ),
              ],
            ),
          ),
        ),
        if (_selectedType == 'dominion')
          Padding(
            padding: const EdgeInsets.fromLTRB(
              VSpacing.md,
              VSpacing.sm,
              VSpacing.md,
              0,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final type in DominionType.values) ...[
                    _PrestigeFilterChip(
                      label: type.displayName,
                      selected: _selectedDominionType == type.name,
                      onTap: () => setState(() {
                        _selectedDominionType =
                            _selectedDominionType == type.name ? null : type.name;
                        _loadData();
                      }),
                    ),
                    const SizedBox(width: 6),
                  ],
                ],
              ),
            ),
          ),
        const SizedBox(height: VSpacing.sm),
        Expanded(
          child: VTabs(
            tabs: [
              VTabEntry(
                label: const Text('Browse'),
                child: _WorldList(worlds: _worlds, loading: _loading),
              ),
              VTabEntry(
                label: const Text('Trending'),
                child: _WorldList(worlds: _trending, loading: _loading),
              ),
              VTabEntry(
                label: const Text('Featured'),
                child: _WorldList(worlds: _featured, loading: _loading),
              ),
            ],
          ),
        ),
      ],
    );

    if (widget.embedded) {
      return ColoredBox(
        color: PrestigeNoir.bg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                VSpacing.sm,
                VSpacing.sm,
                VSpacing.md,
                VSpacing.xs,
              ),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Back to Home',
                    onPressed: widget.onClose ?? () => context.pop(),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: PrestigeNoir.muted,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Discover Worlds',
                      style: TextStyle(
                        fontSize: VFontSize.headlineSm,
                        fontWeight: VFontWeight.bold,
                        color: PrestigeNoir.foreground,
                      ),
                    ),
                  ),
                  if (canCreateWorld)
                    IconButton(
                      tooltip: 'Create world',
                      onPressed: () => context.push('/create-world'),
                      icon: const Icon(
                        Icons.add,
                        color: PrestigeNoir.accent,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(child: body),
          ],
        ),
      );
    }

    return VHubPage(
      title: 'Discover Worlds',
      showBack: true,
      footer: canCreateWorld
          ? Padding(
              padding: const EdgeInsets.all(VSpacing.md),
              child: VButton(
                label: 'Create World',
                isFullWidth: true,
                icon: const Icon(VIcons.plus, size: VIconSize.base),
                onPressed: () => context.push('/create-world'),
              ),
            )
          : null,
      body: body,
    );
  }
}

class _DiscoverySearchPill extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;

  const _DiscoverySearchPill({
    required this.controller,
    this.onChanged,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: PrestigeNoir.surfaceRaised,
        borderRadius: BorderRadius.circular(VRadius.md),
        border: Border.all(color: PrestigeNoir.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: VSpacing.md),
      child: Row(
        children: [
          const Icon(
            VIcons.search,
            size: VIconSize.md,
            color: PrestigeNoir.mutedDim,
          ),
          const SizedBox(width: VSpacing.sm),
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(
                fontSize: VFontSize.bodySm,
                color: PrestigeNoir.foreground,
              ),
              onChanged: onChanged,
              decoration: const InputDecoration(
                hintText: 'Search worlds...',
                hintStyle: TextStyle(color: PrestigeNoir.mutedDim),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          if (controller.text.isNotEmpty && onClear != null)
            GestureDetector(
              onTap: onClear,
              child: const Icon(
                VIcons.x,
                size: VIconSize.md,
                color: PrestigeNoir.mutedDim,
              ),
            ),
        ],
      ),
    );
  }
}

class _WorldList extends ConsumerWidget {
  final List<Map<String, dynamic>> worlds;
  final bool loading;

  const _WorldList({required this.worlds, required this.loading});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (loading) {
      return ListView.builder(
        padding: const EdgeInsets.all(VSpacing.md),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            height: 220,
            decoration: BoxDecoration(
              color: PrestigeNoir.surfaceRaised,
              borderRadius: BorderRadius.circular(VRadius.lg),
              border: Border.all(color: PrestigeNoir.borderLight),
            ),
            child: const Pulse(),
          );
        },
      );
    }

    if (worlds.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.explore_outlined,
              size: 48,
              color: PrestigeNoir.mutedDim,
            ),
            SizedBox(height: VSpacing.md),
            Text(
              'No worlds found',
              style: TextStyle(
                fontWeight: VFontWeight.semiBold,
                color: PrestigeNoir.foreground,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        VSpacing.md,
        VSpacing.sm,
        VSpacing.md,
        VSpacing.lg,
      ),
      itemCount: worlds.length,
      itemBuilder: (context, index) {
        final worldData = worlds[index];
        final world = World.fromSupabase(worldData);
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _PrestigeDiscoveryCard(world: world, index: index),
        );
      },
    );
  }
}

class _PrestigeDiscoveryCard extends ConsumerWidget {
  final World world;
  final int index;

  const _PrestigeDiscoveryCard({
    required this.world,
    required this.index,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resident = ref.watch(residentProvider).resident;
    final isLocked = resident != null && !canAccessWorld(resident, world);
    final tierLabel = world.requiredTier != null
        ? 'Tier ${world.requiredTier}'
        : world.type.name;

    return VPrestigeCard(
      padding: EdgeInsets.zero,
      onTap: () => context.push(exploreWorldPath(world.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(VRadius.bento),
            ),
            child: SizedBox(
              height: 100,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  WorldBanner(
                    worldId: world.id,
                    assetKey: world.assetKey,
                    width: double.infinity,
                    height: 100,
                    worldType: world.type,
                    prestige: world.prestige,
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 40,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            PrestigeNoir.surfaceRaised.withValues(alpha: 0.95),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        world.name,
                        style: const TextStyle(
                          fontSize: VFontSize.bodyMd,
                          fontWeight: VFontWeight.bold,
                          color: PrestigeNoir.foreground,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: PrestigeNoir.accentSoft,
                        borderRadius: BorderRadius.circular(VRadius.xs),
                      ),
                      child: Text(
                        tierLabel.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: VFontWeight.semiBold,
                          letterSpacing: 0.5,
                          color: PrestigeNoir.accent,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      VIcons.users,
                      size: VIconSize.xs,
                      color: PrestigeNoir.muted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${world.memberCount} residents',
                      style: const TextStyle(
                        fontSize: VFontSize.bodySm,
                        color: PrestigeNoir.muted,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '★ P${world.prestige}',
                      style: const TextStyle(
                        fontSize: VFontSize.bodySm,
                        color: PrestigeNoir.accent,
                        fontWeight: VFontWeight.semiBold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  world.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: VFontSize.bodySm,
                    color: PrestigeNoir.muted,
                    height: 1.5,
                  ),
                ),
                if (isLocked) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: PrestigeNoir.surface,
                      borderRadius: BorderRadius.circular(VRadius.xs),
                      border: Border.all(color: PrestigeNoir.border),
                    ),
                    child: const Text(
                      'Locked',
                      style: TextStyle(
                        fontSize: 10,
                        color: PrestigeNoir.muted,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrestigeFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PrestigeFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? PrestigeNoir.accentSoft : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? PrestigeNoir.accent : PrestigeNoir.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: VFontSize.labelSm,
            fontWeight: selected ? VFontWeight.semiBold : VFontWeight.medium,
            color: selected ? PrestigeNoir.accent : PrestigeNoir.muted,
          ),
        ),
      ),
    );
  }
}
