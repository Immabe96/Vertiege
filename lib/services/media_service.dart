import 'dart:io';
import 'supabase.dart';

class MediaService {
  static const _avatarBucket = 'avatars';
  static const _postBucket = 'post-media';
  static const _maxFileSize = 10 * 1024 * 1024; // 10MB
  static const _allowedImages = ['jpg', 'jpeg', 'png', 'webp', 'gif'];

  static bool _isValidImage(String filePath) {
    final ext = filePath.split('.').last.toLowerCase();
    return _allowedImages.contains(ext);
  }

  static Future<String?> uploadAvatar(String filePath, String residentId) async {
    if (!isSupabaseConfigured() || !_isValidImage(filePath)) return null;

    final file = File(filePath);
    if ((await file.length()) > _maxFileSize) return null;

    final client = getSupabase();
    final ext = filePath.split('.').last.toLowerCase();
    final fileName = '$residentId.$ext'; // Overwrite old avatar

    try {
      // Remove old avatar first (ignore if not found)
      await client.storage.from(_avatarBucket).remove([fileName]);
      await client.storage.from(_avatarBucket).upload(fileName, file);
      return client.storage.from(_avatarBucket).getPublicUrl(fileName);
    } catch (_) {
      return null;
    }
  }

  static Future<String?> uploadPostImage(String filePath, String residentId) async {
    if (!isSupabaseConfigured() || !_isValidImage(filePath)) return null;

    final file = File(filePath);
    if ((await file.length()) > _maxFileSize) return null;

    final client = getSupabase();
    final ext = filePath.split('.').last.toLowerCase();
    final fileName = '${residentId}_${DateTime.now().millisecondsSinceEpoch}.$ext';

    try {
      await client.storage.from(_postBucket).upload(fileName, file);
      return client.storage.from(_postBucket).getPublicUrl(fileName);
    } catch (_) {
      return null;
    }
  }
}
