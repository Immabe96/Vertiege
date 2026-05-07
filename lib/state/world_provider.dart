import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/tiers.dart';
import '../models/world.dart';
import '../models/post.dart';
import '../models/alliance.dart';
import '../services/supabase.dart';
import '../services/world_service.dart';
import '../services/storage_service.dart';
import '../services/council_service.dart';
import '../services/prestige_service.dart';
import '../services/store_service.dart';
import '../utils/id_generator.dart';
import 'channel_provider.dart';

class WorldState {
  final Map<String, World> worlds;
  final bool isLoading;
  final List<Alliance> alliances;

  const WorldState({this.worlds = const {}, this.isLoading = true, this.alliances = const []});

  WorldState copyWith({Map<String, World>? worlds, bool? isLoading, List<Alliance>? alliances}) =>
      WorldState(
        worlds: worlds ?? this.worlds,
        isLoading: isLoading ?? this.isLoading,
        alliances: alliances ?? this.alliances,
      );
}

class WorldNotifier extends Notifier<WorldState> {
  @override
  WorldState build() {
    // Load local config worlds immediately — no network needed
    return WorldState(worlds: Map<String, World>.from(worldsConfig), isLoading: false);
  }

  Future<void> loadWorlds() async {
    // Start with local worlds already showing
    final merged = <String, World>{...state.worlds};

    // Load user-created worlds from local storage (no network needed)
    try {
      final userWorlds = await _loadUserWorlds().timeout(const Duration(seconds: 3));
      merged.addAll(userWorlds);
    } catch (_) {}

    // Try loading remote worlds — fail silently, local worlds still show
    if (isSupabaseConfigured()) {
      try {
        final remote = await WorldService.loadWorlds().timeout(const Duration(seconds: 5));
        for (final data in remote) {
          final id = data['id'] as String?;
          if (id != null && !merged.containsKey(id)) {
            merged[id] = World.fromSupabase(data);
          }
        }
      } catch (_) {}
    }

    state = state.copyWith(worlds: merged);
    try { await _loadAlliances().timeout(const Duration(seconds: 3)); } catch (_) {}
    state = state.copyWith(alliances: state.alliances);
  }

  World? getWorld(String worldId) => state.worlds[worldId];

  List<World> get worldsList => state.worlds.values.toList();

  Future<String> createWorld({
    required String name,
    required String description,
    required String sovereignId,
    required String sovereignName,
    String icon = 'earth',
  }) async {
    final worldData = await WorldService.createWorld(
      name: name,
      type: 'dominion',
      description: description,
      sovereignId: sovereignId,
      sovereignName: sovereignName,
      icon: icon,
    );

    final worldId = worldData?['id'] as String? ?? generateId();

    final channelNotifier = ref.read(channelProvider.notifier);
    final channels = await WorldService.createDefaultChannels(worldId);
    if (channels.isNotEmpty) {
      channelNotifier.cacheChannels(worldId, channels);
    }

    final newWorld = World(
      id: worldId,
      name: name,
      type: WorldType.dominion,
      description: description,
      sovereignId: sovereignId,
      sovereignName: sovereignName,
      icon: icon,
    );

    state = state.copyWith(
      worlds: {...state.worlds, worldId: newWorld},
    );

    await _persistUserWorld(newWorld);

    return worldId;
  }

  void updateWorldSettings({
    required String worldId,
    String? name,
    String? description,
    String? icon,
  }) {
    final world = state.worlds[worldId];
    if (world == null) return;

    final updated = world.copyWith(
      name: name ?? world.name,
      description: description ?? world.description,
      icon: icon ?? world.icon,
    );

    state = state.copyWith(
      worlds: {...state.worlds, worldId: updated},
    );

    _persistUserWorld(updated);
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
      world.sovereignId, memberTiers, world,
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
      state = state.copyWith(
        worlds: {...state.worlds, worldId: updated},
      );
      _persistUserWorld(updated);
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
    state = state.copyWith(
      worlds: {...state.worlds, worldId: updated},
    );
    _persistUserWorld(updated);
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
    _persistUserWorld(updated);
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
          state = state.copyWith(
            worlds: {...state.worlds, worldId: updated},
          );
          _persistUserWorld(updated);
        }
      }
    }

    return actions;
  }

  Future<StorePurchaseState> boostWorld(String worldId) async {
    final world = state.worlds[worldId];
    if (world == null || world.type != WorldType.dominion) {
      return StorePurchaseState.error;
    }
    if (world.boostsRemaining <= 0) return StorePurchaseState.error;

    final result = await StoreService.buyWorldBoost();
    if (result != StorePurchaseState.purchased) return result;

    final now = DateTime.now();
    final thisMonth = now.year * 12 + now.month;
    final newCount = world.lastBoostMonth == thisMonth ? world.boostCount + 1 : 1;

    final updated = world.copyWith(
      activityScore: world.activityScore + World.boostActivityPoints,
      boostCount: newCount,
      lastBoostMonth: thisMonth,
    );
    state = state.copyWith(worlds: {...state.worlds, worldId: updated});
    _persistUserWorld(updated);

    return StorePurchaseState.purchased;
  }

  void formAlliance(String worldId1, String worldId2) {
    final w1 = state.worlds[worldId1];
    final w2 = state.worlds[worldId2];
    if (w1 == null || w2 == null) return;
    final exists = state.alliances.any((a) =>
        (a.worldId1 == worldId1 && a.worldId2 == worldId2) ||
        (a.worldId1 == worldId2 && a.worldId2 == worldId1));
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
      final alliances =
          list.map((e) => Alliance.fromJson(e as Map<String, dynamic>)).toList();
      state = state.copyWith(alliances: alliances);
    } catch (_) {}
  }

  void _persistAlliances() {
    final list = state.alliances.map((a) => a.toJson()).toList();
    StorageService.setStringDebounced('@alliances_data', jsonEncode(list));
  }

  Future<Map<String, World>> _loadUserWorlds() async {
    final raw = await StorageService.getString(StorageService.userWorldsKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final list = jsonDecode(raw) as List;
      final result = <String, World>{};
      for (final e in list) {
        final w = World.fromJson(e);
        result[w.id] = w;
      }
      return result;
    } catch (_) {
      return {};
    }
  }

  Future<void> _persistUserWorld(World world) async {
    final worlds = await _loadUserWorlds();
    worlds[world.id] = world;
    final list = worlds.values.map((w) => w.toJson()).toList();
    StorageService.setStringDebounced(
      StorageService.userWorldsKey,
      jsonEncode(list),
    );
  }
}

final worldProvider = NotifierProvider<WorldNotifier, WorldState>(
  WorldNotifier.new,
);
