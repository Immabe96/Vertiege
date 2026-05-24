import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/channel.dart';
import '../services/world_service.dart';
import '../utils/id_generator.dart';

class ChannelState {
  final Map<String, List<WorldChannel>> channelsByWorld;
  final bool isLoading;
  final String? error;

  const ChannelState({
    this.channelsByWorld = const {},
    this.isLoading = false,
    this.error,
  });

  ChannelState copyWith({
    Map<String, List<WorldChannel>>? channelsByWorld,
    bool? isLoading,
    String? error,
  }) => ChannelState(
    channelsByWorld: channelsByWorld ?? this.channelsByWorld,
    isLoading: isLoading ?? this.isLoading,
    error: error,
  );
}

class ChannelNotifier extends Notifier<ChannelState> {
  @override
  ChannelState build() => const ChannelState();

  Future<void> loadChannels(String worldId, {bool force = false}) async {
    if (!force && state.channelsByWorld.containsKey(worldId)) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final channels = await WorldService.getChannels(worldId);
      state = state.copyWith(
        isLoading: false,
        channelsByWorld: {...state.channelsByWorld, worldId: channels},
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void cacheChannels(String worldId, List<WorldChannel> channels) {
    state = state.copyWith(
      channelsByWorld: {...state.channelsByWorld, worldId: channels},
    );
  }

  Future<void> ensureDefaultChannels(String worldId) async {
    final channels = await WorldService.createDefaultChannels(worldId);
    state = state.copyWith(
      channelsByWorld: {...state.channelsByWorld, worldId: channels},
    );
  }

  List<WorldChannel> getChannels(String worldId) =>
      state.channelsByWorld[worldId] ?? [];

  Future<void> createChannel({
    required String worldId,
    required String name,
    String? description,
    ChannelType channelType = ChannelType.text,
  }) async {
    final existing = List<WorldChannel>.from(
      state.channelsByWorld[worldId] ?? const [],
    );
    final channel = WorldChannel(
      id: generateId(),
      worldId: worldId,
      name: name,
      description: description,
      channelType: channelType,
      position: existing.length,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    await WorldService.createChannel(channel);
    state = state.copyWith(
      channelsByWorld: {
        ...state.channelsByWorld,
        worldId: [...existing, channel],
      },
    );
  }

  Future<void> deleteChannel(String worldId, String channelId) async {
    await WorldService.deleteChannel(channelId);
    final channels = (state.channelsByWorld[worldId] ?? const [])
        .where((c) => c.id != channelId || c.isDefault)
        .toList();
    state = state.copyWith(
      channelsByWorld: {...state.channelsByWorld, worldId: channels},
    );
  }

  Future<void> renameChannel(
    String worldId,
    String channelId,
    String newName,
  ) async {
    await WorldService.renameChannel(channelId, newName);
    final channels = (state.channelsByWorld[worldId] ?? const []).map((c) {
      if (c.id == channelId) return c.copyWith(name: newName);
      return c;
    }).toList();
    state = state.copyWith(
      channelsByWorld: {...state.channelsByWorld, worldId: channels},
    );
  }

  void clearForSignOut() {
    state = const ChannelState();
  }
}

final channelProvider = NotifierProvider<ChannelNotifier, ChannelState>(
  ChannelNotifier.new,
);
