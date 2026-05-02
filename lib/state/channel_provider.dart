import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/channel.dart';
import '../services/world_service.dart';
import '../services/storage_service.dart';
import '../utils/id_generator.dart';

class ChannelState {
  final Map<String, List<WorldChannel>> channelsByWorld;
  final bool isLoading;

  const ChannelState({this.channelsByWorld = const {}, this.isLoading = false});

  ChannelState copyWith({
    Map<String, List<WorldChannel>>? channelsByWorld,
    bool? isLoading,
  }) =>
      ChannelState(
        channelsByWorld: channelsByWorld ?? this.channelsByWorld,
        isLoading: isLoading ?? this.isLoading,
      );
}

class ChannelNotifier extends StateNotifier<ChannelState> {
  ChannelNotifier() : super(const ChannelState());

  Future<void> loadChannels(String worldId) async {
    if (state.channelsByWorld.containsKey(worldId)) return;

    var channels = await WorldService.getChannels(worldId);
    if (channels.isEmpty) {
      channels = await _loadLocal(worldId);
    }
    if (channels.isEmpty) {
      channels = await _createDefaults(worldId);
    }

    state = state.copyWith(
      channelsByWorld: {...state.channelsByWorld, worldId: channels},
    );
  }

  void cacheChannels(String worldId, List<WorldChannel> channels) {
    state = state.copyWith(
      channelsByWorld: {...state.channelsByWorld, worldId: channels},
    );
  }

  Future<void> ensureDefaultChannels(String worldId) async {
    if (state.channelsByWorld[worldId]?.isNotEmpty == true) return;
    final channels = await _createDefaults(worldId);
    state = state.copyWith(
      channelsByWorld: {...state.channelsByWorld, worldId: channels},
    );
  }

  List<WorldChannel> getChannels(String worldId) =>
      state.channelsByWorld[worldId] ?? [];

  void createChannel({
    required String worldId,
    required String name,
    String? description,
    ChannelType channelType = ChannelType.text,
  }) {
    final channels = List<WorldChannel>.from(state.channelsByWorld[worldId] ?? []);
    final channel = WorldChannel(
      id: generateId(),
      worldId: worldId,
      name: name,
      description: description,
      channelType: channelType,
      position: channels.length,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    channels.add(channel);
    state = state.copyWith(
      channelsByWorld: {...state.channelsByWorld, worldId: channels},
    );
    _persist(worldId, channels);
  }

  void deleteChannel(String worldId, String channelId) {
    final channels = (state.channelsByWorld[worldId] ?? [])
        .where((c) => c.id != channelId && !c.isDefault)
        .toList();
    state = state.copyWith(
      channelsByWorld: {...state.channelsByWorld, worldId: channels},
    );
    _persist(worldId, channels);
  }

  void renameChannel(String worldId, String channelId, String newName) {
    final channels = (state.channelsByWorld[worldId] ?? []).map((c) {
      if (c.id == channelId) return c.copyWith(name: newName);
      return c;
    }).toList();
    state = state.copyWith(
      channelsByWorld: {...state.channelsByWorld, worldId: channels},
    );
    _persist(worldId, channels);
  }

  Future<List<WorldChannel>> _createDefaults(String worldId) async {
    final channels = await WorldService.createDefaultChannels(worldId);
    if (channels.isEmpty) {
      final local = _defaultChannels(worldId);
      _persist(worldId, local);
      return local;
    }
    _persist(worldId, channels);
    return channels;
  }

  List<WorldChannel> _defaultChannels(String worldId) {
    const cfg = [
      ('general', 'General discussion', ChannelType.text),
      ('lounge', 'Off-topic and casual chat', ChannelType.text),
      ('introductions', 'New residents introduce themselves', ChannelType.text),
    ];
    return [
      for (var i = 0; i < cfg.length; i++)
        WorldChannel(
          id: generateId(),
          worldId: worldId,
          name: cfg[i].$1,
          description: cfg[i].$2,
          channelType: cfg[i].$3,
          position: i,
          isDefault: true,
          createdAt: DateTime.now().millisecondsSinceEpoch,
        ),
    ];
  }

  Future<List<WorldChannel>> _loadLocal(String worldId) async {
    final all = await _loadAllLocal();
    return all[worldId] ?? [];
  }

  Future<Map<String, List<WorldChannel>>> _loadAllLocal() async {
    final raw = await StorageService.getString(StorageService.channelsKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final result = <String, List<WorldChannel>>{};
      for (final entry in map.entries) {
        result[entry.key] = (entry.value as List)
            .map((e) => WorldChannel.fromJson(e))
            .toList();
      }
      return result;
    } catch (_) {
      return {};
    }
  }

  void _persist(String worldId, List<WorldChannel> channels) {
    _loadAllLocal().then((all) {
      all[worldId] = channels;
      final encoded = <String, dynamic>{};
      for (final entry in all.entries) {
        encoded[entry.key] = entry.value.map((c) => c.toJson()).toList();
      }
      StorageService.setStringDebounced(StorageService.channelsKey, jsonEncode(encoded));
    });
  }
}

final channelProvider = StateNotifierProvider<ChannelNotifier, ChannelState>(
  (ref) => ChannelNotifier(),
);
