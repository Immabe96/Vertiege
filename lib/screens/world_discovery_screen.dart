import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/world.dart';
import '../../services/admin_access_service.dart';
import '../../services/world_service.dart';
import '../../state/resident_provider.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_commune_colors.dart';
import '../../theme/v_tokens.dart';
import '../../widgets/core/shimmer.dart';
import 'package:vertiege/ui/ui.dart';
import '../../widgets/worlds/world_card.dart';

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
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      _loadData();
    });
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
            child: TextField(
              controller: _searchController,
              onChanged: (v) {
                setState(() {});
                _onSearchChanged(v);
              },
              decoration: InputDecoration(
                hintText: 'Search worlds...',
                prefixIcon: Icon(
                  VIcons.search,
                  color: isDark
                      ? VColors.onSurfaceVariantDark
                      : VColors.onSurfaceVariant,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(VIcons.x, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                          _loadData();
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark
                    ? VColors.surfaceContainerDark
                    : VColors.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(VRadius.lg),
                  borderSide: BorderSide(
                    color: isDark
                        ? VColors.outlineVariantDark
                        : VColors.outlineVariant,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(VRadius.lg),
                  borderSide: BorderSide(
                    color: isDark
                        ? VColors.outlineVariantDark
                        : VColors.outlineVariant,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: VSpacing.md),
            child: Wrap(
              spacing: VSpacing.sm,
              runSpacing: VSpacing.sm,
              children: [
                _FilterChip(
                  label: 'All Types',
                  selected: _selectedType == null,
                  onTap: () => setState(() {
                    _selectedType = null;
                    _selectedDominionType = null;
                    _loadData();
                  }),
                ),
                _FilterChip(
                  label: 'Wealth',
                  selected: _selectedType == 'wealth',
                  onTap: () => setState(() {
                    _selectedType = 'wealth';
                    _selectedDominionType = null;
                    _loadData();
                  }),
                ),
                _FilterChip(
                  label: 'Profession',
                  selected: _selectedType == 'profession',
                  onTap: () => setState(() {
                    _selectedType = 'profession';
                    _selectedDominionType = null;
                    _loadData();
                  }),
                ),
                _FilterChip(
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
          if (_selectedType == 'dominion')
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: VSpacing.md,
                vertical: VSpacing.sm,
              ),
              child: Wrap(
                spacing: VSpacing.sm,
                runSpacing: VSpacing.sm,
                children: DominionType.values.map((type) {
                  return _FilterChip(
                    label: type.displayName,
                    selected: _selectedDominionType == type.name,
                    onTap: () => setState(() {
                      _selectedDominionType = _selectedDominionType == type.name
                          ? null
                          : type.name;
                      _loadData();
                    }),
                  );
                }).toList(),
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
        color: VCommuneColors.surfacePrimary,
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
                      color: VCommuneColors.textMuted,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Discover worlds',
                      style: TextStyle(
                        fontSize: VFontSize.headlineSm,
                        fontWeight: VFontWeight.bold,
                        color: VCommuneColors.headerPrimary,
                      ),
                    ),
                  ),
                  if (canCreateWorld)
                    IconButton(
                      tooltip: 'Create world',
                      onPressed: () => context.push('/create-world'),
                      icon: const Icon(
                        Icons.add,
                        color: VCommuneColors.statusOnline,
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
                icon: Icon(VIcons.plus, size: 18),
                onPressed: () => context.push('/create-world'),
              ),
            )
          : null,
      body: body,
    );
  }
}

class _WorldList extends StatelessWidget {
  final List<Map<String, dynamic>> worlds;
  final bool loading;

  const _WorldList({required this.worlds, required this.loading});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (loading) {
      return ListView.builder(
        padding: const EdgeInsets.all(VSpacing.md),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: VSpacing.sm),
            height: 120,
            decoration: BoxDecoration(
              color: isDark
                  ? VColors.surfaceContainerDark
                  : VColors.surfaceContainer,
              borderRadius: BorderRadius.circular(VRadius.lg),
            ),
            child: const Pulse(),
          );
        },
      );
    }

    if (worlds.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.explore_outlined,
              size: 48,
              color: VColors.onSurfaceVariant,
            ),
            const SizedBox(height: VSpacing.md),
            const Text(
              'No worlds found',
              style: TextStyle(fontWeight: VFontWeight.semiBold),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(VSpacing.md),
      itemCount: worlds.length,
      itemBuilder: (context, index) {
        final worldData = worlds[index];
        final world = World.fromSupabase(worldData);
        return Padding(
          padding: const EdgeInsets.only(bottom: VSpacing.sm),
          child: WorldCard(world: world, index: index, plainStyle: true),
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: VSpacing.md,
          vertical: VSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: selected
              ? VColors.primary.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(VRadius.pill),
          border: Border.all(
            color: selected
                ? VColors.primary
                : VColors.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: VFontSize.labelSm,
            fontWeight: selected ? VFontWeight.semiBold : VFontWeight.regular,
            color: selected ? VColors.primary : null,
          ),
        ),
      ),
    );
  }
}
