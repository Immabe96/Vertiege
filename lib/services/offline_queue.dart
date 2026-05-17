import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/id_generator.dart';

class QueueItem {
  final String id;
  final String type;
  final Map<String, dynamic> data;
  final int timestamp;
  final int retryCount;

  QueueItem({
    required this.id,
    required this.type,
    required this.data,
    required this.timestamp,
    this.retryCount = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'data': data,
    'timestamp': timestamp,
    'retryCount': retryCount,
  };

  factory QueueItem.fromJson(Map<String, dynamic> json) => QueueItem(
    id: json['id'] as String,
    type: json['type'] as String,
    data: Map<String, dynamic>.from(json['data'] as Map),
    timestamp: json['timestamp'] as int,
    retryCount: json['retryCount'] as int? ?? 0,
  );
}

class OfflineQueue {
  static const String _key = '@offline_queue';
  static const int _maxRetries = 3;

  static Future<List<QueueItem>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => QueueItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<void> enqueue(String type, Map<String, dynamic> data) async {
    final items = await getAll();
    final item = QueueItem(
      id: generateId(),
      type: type,
      data: data,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    items.add(item);
    await _save(items);
  }

  static Future<void> dequeue(String id) async {
    final items = await getAll();
    items.removeWhere((item) => item.id == id);
    await _save(items);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  static Future<void> retryAll(Future<void> Function(QueueItem) retryFn) async {
    final items = await getAll();
    final toRemove = <String>[];
    for (final item in items) {
      if (item.retryCount >= _maxRetries) {
        toRemove.add(item.id);
        continue;
      }
      try {
        await retryFn(item);
        toRemove.add(item.id);
      } catch (_) {
        final updated = QueueItem(
          id: item.id,
          type: item.type,
          data: item.data,
          timestamp: item.timestamp,
          retryCount: item.retryCount + 1,
        );
        final idx = items.indexWhere((i) => i.id == item.id);
        if (idx != -1) items[idx] = updated;
      }
    }
    final remaining = items.where((i) => !toRemove.contains(i.id)).toList();
    await _save(remaining);
  }

  static Future<void> _save(List<QueueItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(items.map((e) => e.toJson()).toList());
    await prefs.setString(_key, json);
  }
}
