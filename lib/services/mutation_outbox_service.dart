import 'dart:convert';

import '../models/mutation_outbox_item.dart';
import 'storage_service.dart';

typedef MutationReplayHandler =
    Future<void> Function(MutationOutboxItem mutation);

class MutationOutboxService {
  MutationOutboxService._();

  static const String _key = '@mutation_outbox_v1';
  static const int maxRetries = 5;

  static Future<List<MutationOutboxItem>> getAll() async {
    final raw = await StorageService.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map(
          (item) => MutationOutboxItem.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  static Future<void> enqueue(String type, Map<String, dynamic> payload) async {
    final items = await getAll();
    final key = _dedupeKey(type, payload);
    final existingIndex = items.indexWhere(
      (item) => _dedupeKey(item.type, item.payload) == key,
    );
    final item = MutationOutboxItem(type: type, payload: payload);
    if (existingIndex == -1) {
      items.add(item);
    } else {
      items[existingIndex] = item;
    }
    await _save(items);
  }

  static Future<void> remove(String id) async {
    final items = await getAll();
    items.removeWhere((item) => item.id == id);
    await _save(items);
  }

  static Future<void> replay(MutationReplayHandler handler) async {
    final items = await getAll();
    final remaining = <MutationOutboxItem>[];

    for (final item in items) {
      if (item.retryCount >= maxRetries) {
        remaining.add(item);
        continue;
      }

      try {
        await handler(item);
      } catch (error) {
        remaining.add(
          item.copyWith(
            retryCount: item.retryCount + 1,
            lastAttemptAt: DateTime.now(),
            error: error.toString(),
          ),
        );
      }
    }

    await _save(remaining);
  }

  static Future<void> clear() async {
    await StorageService.remove(_key);
  }

  static Future<void> _save(List<MutationOutboxItem> items) async {
    final json = jsonEncode(items.map((item) => item.toJson()).toList());
    await StorageService.setString(_key, json);
  }

  static String _dedupeKey(String type, Map<String, dynamic> payload) {
    final subject =
        payload['postId'] ??
        payload['id'] ??
        payload['worldId'] ??
        payload['residentId'] ??
        '';
    return '$type:$subject';
  }
}
