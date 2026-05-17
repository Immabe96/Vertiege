import 'dart:convert';
import 'storage_service.dart';

class BackupService {
  static const int currentSchemaVersion = 1;

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
    return jsonEncode({
      'schemaVersion': currentSchemaVersion,
      'backup': data,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  static Future<bool> restoreBackup(String json) async {
    try {
      final data = jsonDecode(json) as Map<String, dynamic>;

      final schemaVersion = data['schemaVersion'];
      if (schemaVersion is! int ||
          schemaVersion < 1 ||
          schemaVersion > currentSchemaVersion) {
        throw Exception(
          'Incompatible backup schema version: $schemaVersion '
          '(supported: 1-$currentSchemaVersion)',
        );
      }

      final backup = data['backup'];
      if (backup is! Map<String, dynamic>) {
        throw Exception('Invalid backup structure: missing backup object');
      }

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
        final value = entry.value;
        if (value is! String) {
          throw Exception(
            'Invalid type for key "${entry.key}": expected String',
          );
        }
        if (value.length > 500000) continue; // reject >500KB
        await StorageService.setString(entry.key, value);
      }

      return true;
    } catch (e) {
      return false;
    }
  }
}
