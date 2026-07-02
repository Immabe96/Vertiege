import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'supabase.dart';

class MediaService {
  static const _avatarBucket = 'avatars';
  static const _postBucket = 'post-media';
  static const _maxFileSize = 10 * 1024 * 1024; // 10MB
  static const _allowedImages = ['jpg', 'jpeg', 'png', 'webp', 'gif'];
  static const _maxDimension = 1920;
  static const _compressQuality = 85;

  static bool _isValidImage(String filePath) {
    final ext = filePath.split('.').last.toLowerCase();
    return _allowedImages.contains(ext);
  }

  static Future<File?> _compressImage(File file) async {
    try {
      final targetPath =
          '${file.parent.path}/compressed_${file.uri.pathSegments.last.replaceAll(RegExp(r'\.[^.]+$'), '.jpg')}';
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        minHeight: _maxDimension,
        quality: _compressQuality,
      );
      if (result == null) return null;
      return File(result.path);
    } catch (_) {
      return null;
    }
  }

  static Future<String?> uploadAvatar(
    String filePath,
    String residentId,
  ) async {
    if (!isSupabaseConfigured() || !_isValidImage(filePath)) return null;

    final file = File(filePath);
    if ((await file.length()) > _maxFileSize) return null;

    final client = getSupabase();
    final ext = filePath.split('.').last.toLowerCase();
    final fileName = 'avatars/$residentId.$ext'; // Overwrite old avatar

    try {
      final compressed = await _compressImage(file);
      final uploadFile = compressed ?? file;
      // Remove old avatar first (ignore if not found)
      await client.storage.from(_avatarBucket).remove([fileName]);
      await client.storage.from(_avatarBucket).upload(fileName, uploadFile);
      if (compressed != null && compressed.path != file.path) {
        await compressed.delete();
      }
      return client.storage.from(_avatarBucket).getPublicUrl(fileName);
    } catch (_) {
      return null;
    }
  }

  static Future<String?> uploadPostImage(
    String filePath,
    String residentId,
  ) async {
    if (!isSupabaseConfigured() || !_isValidImage(filePath)) return null;

    final file = File(filePath);
    if ((await file.length()) > _maxFileSize) return null;

    final client = getSupabase();
    final ext = filePath.split('.').last.toLowerCase();
    final fileName =
        '${residentId}_${DateTime.now().millisecondsSinceEpoch}.$ext';

    try {
      final compressed = await _compressImage(file);
      final uploadFile = compressed ?? file;
      await client.storage.from(_postBucket).upload(fileName, uploadFile);
      if (compressed != null && compressed.path != file.path) {
        await compressed.delete();
      }
      return client.storage.from(_postBucket).getPublicUrl(fileName);
    } catch (_) {
      return null;
    }
  }
}
