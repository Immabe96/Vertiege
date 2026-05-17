import 'dart:convert';
import '../models/post.dart';
import '../models/world.dart';
import 'storage_service.dart';

/// Provides instant-resume caching for feeds and world lists.
/// Data is cached after initial provider load and restored on next startup
/// before the network refresh completes.
class CacheService {
  CacheService._();

  static const String _feedCacheKey = '@cache_feed';
  static const String _worldsCacheKey = '@cache_worlds';

  // ── Feed ──────────────────────────────────────────────

  static Future<void> cacheFeed(List<Post> posts) async {
    if (posts.isEmpty) return;
    final json = jsonEncode(posts.map((p) => _postToJson(p)).toList());
    await StorageService.setString(_feedCacheKey, json);
  }

  static Future<List<Post>?> getCachedFeed() async {
    final raw = await StorageService.getString(_feedCacheKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map(
            (e) => Post(
              id: e['id'] ?? '',
              worldId: e['worldId'] ?? '',
              residentId: e['residentId'] ?? '',
              residentName: e['residentName'] ?? '',
              residentAvatar: e['residentAvatar'] ?? '',
              content: e['content'] ?? '',
              imageUri: e['imageUri'],
              imageUris: (e['imageUris'] as List?)?.cast<String>(),
              timestamp: e['timestamp'] ?? 0,
              isAnnouncement: e['isAnnouncement'] ?? false,
              isPinned: e['isPinned'] ?? false,
              eventTitle: e['eventTitle'],
              eventStartsAt: e['eventStartsAt'],
              eventRsvpIds: (e['eventRsvpIds'] as List?)?.cast<String>() ?? [],
            ),
          )
          .toList();
    } catch (_) {
      return null;
    }
  }

  // ── Worlds ─────────────────────────────────────────────

  static Future<void> cacheWorlds(List<World> worlds) async {
    if (worlds.isEmpty) return;
    final json = jsonEncode(worlds.map((w) => w.toJson()).toList());
    await StorageService.setString(_worldsCacheKey, json);
  }

  static Future<List<World>?> getCachedWorlds() async {
    final raw = await StorageService.getString(_worldsCacheKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => World.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }

  // ── Helpers ────────────────────────────────────────────

  static Map<String, dynamic> _postToJson(Post p) => {
    'id': p.id,
    'worldId': p.worldId,
    'residentId': p.residentId,
    'residentName': p.residentName,
    'residentAvatar': p.residentAvatar,
    'content': p.content,
    'imageUri': p.imageUri,
    'imageUris': p.imageUris,
    'timestamp': p.timestamp,
    'isAnnouncement': p.isAnnouncement,
    'isPinned': p.isPinned,
    'eventTitle': p.eventTitle,
    'eventStartsAt': p.eventStartsAt,
    'eventRsvpIds': p.eventRsvpIds,
  };
}
