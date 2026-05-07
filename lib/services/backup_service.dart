import 'dart:convert';
import 'storage_service.dart';

class BackupService {
  static Future<String> createBackup() async {
    final data = await StorageService.getAll([
      StorageService.residentKey,
      StorageService.postsKey,
      StorageService.notificationsKey,
      StorageService.achievementsKey,
      StorageService.themeKey,
      StorageService.channelsKey,
      StorageService.membershipsKey,
      StorageService.userWorldsKey,
    ]);
    return jsonEncode({'backup': data, 'createdAt': DateTime.now().toIso8601String()});
  }

  static Future<bool> restoreBackup(String json) async {
    try {
      final data = jsonDecode(json) as Map<String, dynamic>;
      final backup = data['backup'] as Map<String, dynamic>;

      final allowedKeys = {
        StorageService.residentKey,
        StorageService.postsKey,
        StorageService.notificationsKey,
        StorageService.achievementsKey,
        StorageService.themeKey,
        StorageService.channelsKey,
        StorageService.membershipsKey,
        StorageService.userWorldsKey,
      };

      for (final entry in backup.entries) {
        if (!allowedKeys.contains(entry.key)) continue;
        final value = entry.value.toString();
        if (value.length > 500000) continue; // reject >500KB
        await StorageService.setString(entry.key, value);
      }

      return true;
    } catch (_) {
      return false;
    }
  }
}
