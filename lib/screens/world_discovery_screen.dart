import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/world.dart';
import '../../services/world_service.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../../widgets/core/shimmer.dart';
import '../../widgets/worlds/world_card.dart';

class WorldDiscoveryScreen extends ConsumerStatefulWidget {
  const WorldDiscoveryScreen({super.key});

  @override
  ConsumerState<WorldDiscoveryScreen> createState() =>
      _WorldDiscoveryScreenState();
}

class _WorldDiscoveryScreenState extends ConsumerState<WorldDiscoveryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
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
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _tabController.dispose();
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

    return Scaffold(
      backgroundColor: isDark ? VColors.surfaceDark : VColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Discover Worlds',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: VFontWeight.semiBold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: VColors.primary,
          unselectedLabelColor: isDark ? VColors.onSurfaceVariantDark : VColors.onSurfaceVariant,
          indicatorColor: VColors.primary,
          tabs: const [
            Tab(text: 'Browse'),
            Tab(text: 'Trending'),
            Tab(text: 'Featured'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(VSpacing.md),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search worlds...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _loadData();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(VRadius.lg),
                ),
              ),
              onChanged: _onSearchChanged,
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
                      _selectedDominionType = _selectedDominionType == type.name ? null : type.name;
                      _loadData();
                    }),
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: VSpacing.sm),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _WorldList(worlds: _worlds, loading: _loading),
                _WorldList(worlds: _trending, loading: _loading),
                _WorldList(worlds: _featured, loading: _loading),
              ],
            ),
          ),
        ],
      ),
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
              color: isDark ? VColors.surfaceContainerDark : VColors.surfaceContainer,
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
            Icon(Icons.explore_outlined, size: 48, color: VColors.onSurfaceVariant),
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
          child: WorldCard(world: world),
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: VSpacing.md, vertical: VSpacing.xs),
        decoration: BoxDecoration(
          color: selected ? VColors.primary.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(VRadius.pill),
          border: Border.all(
            color: selected ? VColors.primary : VColors.outline.withValues(alpha: 0.3),
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
