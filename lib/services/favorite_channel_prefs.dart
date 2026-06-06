import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Per-world favorite (starred) channel IDs — local only.
class FavoriteChannelPrefs {
  FavoriteChannelPrefs._();

  static const _key = '@favorite_channels_by_world';

  static Future<Map<String, Set<String>>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map(
        (worldId, ids) => MapEntry(
          worldId,
          (ids as List).cast<String>().toSet(),
        ),
      );
    } catch (_) {
      return {};
    }
  }

  static Future<Set<String>> loadForWorld(String worldId) async {
    final all = await loadAll();
    return all[worldId] ?? {};
  }

  static Future<Set<String>> toggle({
    required String worldId,
    required String channelId,
  }) async {
    final all = await loadAll();
    final current = Set<String>.from(all[worldId] ?? {});
    if (current.contains(channelId)) {
      current.remove(channelId);
    } else {
      current.add(channelId);
    }
    if (current.isEmpty) {
      all.remove(worldId);
    } else {
      all[worldId] = current;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(all.map((k, v) => MapEntry(k, v.toList()))),
    );
    return current;
  }
}

/// Sort channels with favorites pinned to the top (stable within each group).
List<T> sortChannelsWithFavorites<T>({
  required List<T> channels,
  required Set<String> favoriteIds,
  required String Function(T) idFor,
  int Function(T, T)? compareNonFavorite,
}) {
  if (favoriteIds.isEmpty) {
    if (compareNonFavorite == null) return channels;
    final sorted = List<T>.from(channels);
    sorted.sort(compareNonFavorite);
    return sorted;
  }
  final favorites = <T>[];
  final rest = <T>[];
  for (final ch in channels) {
    if (favoriteIds.contains(idFor(ch))) {
      favorites.add(ch);
    } else {
      rest.add(ch);
    }
  }
  if (compareNonFavorite != null) {
    rest.sort(compareNonFavorite);
  }
  return [...favorites, ...rest];
}
