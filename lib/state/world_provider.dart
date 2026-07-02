import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../config/tiers.dart';
import '../config/world_page_ia.dart';
import '../models/alliance.dart';
import '../models/post.dart';
import '../models/world.dart';
import '../services/council_service.dart';
import '../services/prestige_service.dart';
import '../services/storage_service.dart';
import '../services/world_service.dart';
import '../services/store_service.dart';
import '../utils/id_generator.dart';
import '../utils/rate_limiter.dart';
import 'channel_provider.dart';

part 'world_provider.g.dart';

class WorldState {
  final Map<String, World> worlds;
  final bool isLoading;
  final List<Alliance> alliances;
  final String? loadError;

  const WorldState({
    this.worlds = const {},
    this.isLoading = true,
    this.alliances = const [],
    this.loadError,
  });

  WorldState copyWith({
    Map<String, World>? worlds,
    bool? isLoading,
    List<Alliance>? alliances,
    String? loadError,
    bool clearLoadError = false,
  }) => WorldState(
    worlds: worlds ?? this.worlds,
    isLoading: isLoading ?? this.isLoading,
    alliances: alliances ?? this.alliances,
    loadError: clearLoadError ? null : (loadError ?? this.loadError),
  );
}

@Riverpod(name: 'worldProvider', keepAlive: true)
class WorldNotifier extends _$WorldNotifier {
  @override
  WorldState build() {
    // Load local config worlds immediately — no network needed
    return const WorldState();
  }

  static const String _worldsCacheKey = '@worlds_cache';

  Future<void> loadWorlds() async {
    state = state.copyWith(isLoading: true, clearLoadError: true);
    try {
      final remote = await WorldService.loadWorlds().timeout(
        const Duration(seconds: 8),
      );
      final worlds = <String, World>{};
      for (final data in remote) {
        final world = World.fromSupabase(data);
        if (world.id.isNotEmpty) worlds[world.id] = world;
      }
      state = state.copyWith(
        worlds: worlds,
        isLoading: false,
        clearLoadError: true,
      );
      await _cacheWorlds(worlds);
    } catch (_) {
      final cached = await _loadCachedWorlds();
      final hasCache = cached != null && cached.isNotEmpty;
      state = state.copyWith(
        worlds: cached ?? const {},
        isLoading: false,
        loadError: hasCache
            ? 'Showing cached worlds (sync failed). Pull to refresh.'
            : 'Could not load worlds. Pull to refresh.',
      );
    }

    try {
      await _loadAlliances().timeout(const Duration(seconds: 3));
    } catch (_) {}
    state = state.copyWith(alliances: state.alliances);
  }

  World? getWorld(String worldId) => state.worlds[worldId];

  World? getWorldBySlug(String slug) {
    for (final world in state.worlds.values) {
      if (world.slug == slug) return world;
    }
    return null;
  }

  List<World> get worldsList {
    final worlds = state.worlds.values.toList()
      ..sort((a, b) {
        final bySort = a.sortOrder.compareTo(b.sortOrder);
        return bySort != 0 ? bySort : a.name.compareTo(b.name);
      });
    return worlds;
  }

  Future<String> createWorld({
    required String name,
    required String description,
    required String sovereignId,
    required String sovereignName,
    String icon = 'earth',
    String? dominionType,
    String? worldCurrencyName,
    List<String>? tags,
  }) async {
    if (dominionType != null &&
        !WorldPageIa.isCreatableDominionName(dominionType)) {
      throw StateError(
        'Only Community (sanctuary) and Shop (marketplace) worlds can be created.',
      );
    }
    if (!RateLimiter.canProceed('create_world_$sovereignId', windowMs: 30000, maxCalls: 2)) {
      throw StateError(
        'Please wait a moment before creating another world.',
      );
    }
    final worldData = await WorldService.createWorld(
      name: name,
      type: 'dominion',
      description: description,
      sovereignId: sovereignId,
      sovereignName: sovereignName,
      icon: icon,
      dominionType: dominionType,
      worldCurrencyName: worldCurrencyName,
      tags: tags,
    );

    final worldId = worldData?['id'] as String? ?? generateId();

    final newWorld = World(
      id: worldId,
      slug: worldData?['slug'] as String? ?? '',
      name: name,
      type: WorldType.dominion,
      description: description,
      sovereignId: sovereignId,
      sovereignName: sovereignName,
      icon: icon,
      dominionType: dominionType != null
          ? DominionType.values.firstWhere(
              (t) => t.name == dominionType,
              orElse: () => DominionType.sanctuary,
            )
          : null,
      worldCurrencyName: worldCurrencyName ?? 'Coins',
      tags: tags ?? [],
    );

    final channelNotifier = ref.read(channelProvider.notifier);
    final channels = await WorldService.createDefaultChannels(worldId, world: newWorld);
    if (channels.isNotEmpty) {
      channelNotifier.cacheChannels(worldId, channels);
    }

    state = state.copyWith(worlds: {...state.worlds, worldId: newWorld});

    return worldId;
  }

  Future<void> updateWorldSettings({
    required String worldId,
    String? name,
    String? description,
    String? icon,
  }) async {
    final world = state.worlds[worldId];
    if (world == null) return;

    final updated = world.copyWith(
      name: name ?? world.name,
      description: description ?? world.description,
      icon: icon ?? world.icon,
    );

    state = state.copyWith(worlds: {...state.worlds, worldId: updated});

    await WorldService.updateWorld(
      worldId: worldId,
      name: name,
      description: description,
      icon: icon,
    );
  }

  Future<int> updateWorldPrestige({
    required String worldId,
    required int memberCount,
    required Map<String, int> memberTiers,
    required List<Post> recentPosts,
  }) async {
    final world = state.worlds[worldId];
    if (world == null) return 0;

    final sovereignTier = PrestigeService.resolveSovereignTier(
      world.sovereignId,
      memberTiers,
      world,
    );
    final avgTier = PrestigeService.computeAvgTier(memberTiers);

    final newPrestige = await PrestigeService.recalculateForWorld(
      worldId: worldId,
      world: world,
      memberCount: memberCount,
      avgMemberTier: avgTier,
      sovereignTier: sovereignTier,
      recentPosts: recentPosts,
    );

    if (newPrestige != world.prestige) {
      final updated = world.copyWith(prestige: newPrestige);
      state = state.copyWith(worlds: {...state.worlds, worldId: updated});
    }

    return newPrestige;
  }

  WorldFeatures featuresForWorld(String worldId) {
    final world = state.worlds[worldId];
    if (world == null) return const WorldFeatures();
    final fn = getWorldFeatures;
    return fn(world.prestige, world.type);
  }

  void addActivityScore(String worldId, int points) {
    final world = state.worlds[worldId];
    if (world == null || world.type != WorldType.dominion) return;

    final updated = world.copyWith(activityScore: world.activityScore + points);
    state = state.copyWith(worlds: {...state.worlds, worldId: updated});
    unawaited(WorldService.bumpActivityScore(worldId, points));
  }

  int worldLevelFor(String worldId) {
    final world = state.worlds[worldId];
    if (world == null) return 1;
    if (world.type != WorldType.dominion) return 10;
    return getWorldLevel(world.activityScore);
  }

  int residentCapacityFor(String worldId) {
    final world = state.worlds[worldId];
    if (world == null) return 20;
    if (world.type != WorldType.dominion) return 9999;
    return getResidentCapacity(worldLevelFor(worldId));
  }

  void incrementMemberCount(String worldId) {
    final world = state.worlds[worldId];
    if (world == null) return;
    final updated = world.copyWith(memberCount: world.memberCount + 1);
    state = state.copyWith(worlds: {...state.worlds, worldId: updated});
  }

  void decrementMemberCount(String worldId) {
    final world = state.worlds[worldId];
    if (world == null) return;
    final updated = world.copyWith(
      memberCount: (world.memberCount - 1).clamp(0, 99999),
    );
    state = state.copyWith(worlds: {...state.worlds, worldId: updated});
  }

  Future<List<CouncilAction>> runCouncilCheck(String worldId) async {
    final actions = await CouncilService.checkWorld(worldId);

    for (final action in actions) {
      if (action.type == 'elect' && action.residentId != null) {
        final world = state.worlds[worldId];
        if (world != null) {
          final updated = world.copyWith(
            sovereignId: action.residentId,
            sovereignName: action.residentName ?? world.sovereignName,
          );
          state = state.copyWith(worlds: {...state.worlds, worldId: updated});
        }
      }
    }

    return actions;
  }

  Future<StorePurchaseState> boostWorld(String worldId) async {
    return StorePurchaseState.disabled;
  }

  void formAlliance(String worldId1, String worldId2) {
    final w1 = state.worlds[worldId1];
    final w2 = state.worlds[worldId2];
    if (w1 == null || w2 == null) return;
    final exists = state.alliances.any(
      (a) =>
          (a.worldId1 == worldId1 && a.worldId2 == worldId2) ||
          (a.worldId1 == worldId2 && a.worldId2 == worldId1),
    );
    if (exists) return;

    final alliance = Alliance(
      id: 'ally_${generateId()}',
      worldId1: worldId1,
      worldId2: worldId2,
      worldName1: w1.name,
      worldName2: w2.name,
      formedAt: DateTime.now(),
    );
    state = state.copyWith(alliances: [...state.alliances, alliance]);
    _persistAlliances();
  }

  List<Alliance> alliancesForWorld(String worldId) {
    return state.alliances
        .where((a) => a.worldId1 == worldId || a.worldId2 == worldId)
        .toList();
  }

  Future<void> _loadAlliances() async {
    final raw = await StorageService.getString('@alliances_data');
    if (raw == null || raw.isEmpty) return;
    try {
      final list = jsonDecode(raw) as List;
      final alliances = list
          .map((e) => Alliance.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(alliances: alliances);
    } catch (_) {}
  }

  void _persistAlliances() {
    final list = state.alliances.map((a) => a.toJson()).toList();
    StorageService.setStringDebounced('@alliances_data', jsonEncode(list));
  }

  Future<void> _cacheWorlds(Map<String, World> worlds) async {
    try {
      final json = jsonEncode(
        worlds.values.map((w) {
          final data = <String, dynamic>{
            'id': w.id,
            'slug': w.slug,
            'name': w.name,
            'type': w.type.name,
            'description': w.description,
            'sovereignId': w.sovereignId,
            'sovereignName': w.sovereignName,
            'prestige': w.prestige,
            'icon': w.icon,
            'memberCount': w.memberCount,
            'activityScore': w.activityScore,
            'sortOrder': w.sortOrder,
            'createdAt': w.createdAt,
          };
          if (w.constitution.admission != 'open') {
            data['admission'] = w.constitution.admission;
          }
          if (w.constitution.requiredProfession != null) {
            data['requiredProfession'] = w.constitution.requiredProfession;
          }
          if (w.constitution.minTier != null) {
            data['minTier'] = w.constitution.minTier;
          }
          if (w.constitution.entryFee > 0) {
            data['entryFee'] = w.constitution.entryFee;
          }
          return data;
        }).toList(),
      );
      await StorageService.setString(_worldsCacheKey, json);
    } catch (_) {}
  }

  Future<Map<String, World>?> _loadCachedWorlds() async {
    try {
      final raw = await StorageService.getString(_worldsCacheKey);
      if (raw == null || raw.isEmpty) return null;
      final list = jsonDecode(raw) as List;
      final worlds = <String, World>{};
      for (final item in list) {
        final data = item as Map<String, dynamic>;
        final world = World(
          id: data['id'] as String,
          slug: data['slug'] as String? ?? '',
          name: data['name'] as String? ?? '',
          type: WorldType.values.firstWhere(
            (e) => e.name == data['type'],
            orElse: () => WorldType.dominion,
          ),
          description: data['description'] as String? ?? '',
          sovereignId: data['sovereignId'] as String? ?? '',
          sovereignName: data['sovereignName'] as String? ?? '',
          prestige: data['prestige'] as int? ?? 1,
          icon: data['icon'] as String? ?? 'earth',
          memberCount: data['memberCount'] as int? ?? 0,
          activityScore: data['activityScore'] as int? ?? 0,
          sortOrder: data['sortOrder'] as int? ?? 0,
          createdAt: data['createdAt'] as int? ?? 0,
        );
        if (world.id.isNotEmpty) worlds[world.id] = world;
      }
      return worlds;
    } catch (_) {
      return null;
    }
  }

  void clearForSignOut() {
    state = const WorldState();
  }
}


