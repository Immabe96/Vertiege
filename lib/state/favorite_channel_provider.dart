import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../services/favorite_channel_prefs.dart';

part 'favorite_channel_provider.g.dart';

@Riverpod(name: 'favoriteChannelProvider', keepAlive: true)
class FavoriteChannelNotifier extends _$FavoriteChannelNotifier {
  @override
  Map<String, Set<String>> build() {
    Future.microtask(_load);
    return {};
  }

  Future<void> _load() async {
    state = await FavoriteChannelPrefs.loadAll();
  }

  bool isFavorite(String worldId, String channelId) {
    return state[worldId]?.contains(channelId) ?? false;
  }

  Future<void> toggle(String worldId, String channelId) async {
    final updated = await FavoriteChannelPrefs.toggle(
      worldId: worldId,
      channelId: channelId,
    );
    state = {...state, worldId: updated};
  }
}
