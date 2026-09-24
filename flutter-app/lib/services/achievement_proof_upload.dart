import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'supabase.dart';

/// Picks a gallery image and uploads achievement proof to Supabase storage.
class AchievementProofUpload {
  AchievementProofUpload._();

  static Future<String?> pickGalleryImage({int maxWidth = 1200}) async {
    final picker = ImagePicker();
    final result = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: maxWidth.toDouble(),
    );
    return result?.path;
  }

  static Future<List<String>> pickGalleryImages({
    int maxWidth = 1200,
    int limit = 4,
  }) async {
    final picker = ImagePicker();
    final results = await picker.pickMultiImage(
      maxWidth: maxWidth.toDouble(),
      limit: limit,
    );
    return results.map((x) => x.path).toList();
  }

  static Future<String?> _compressForUpload(String filePath) async {
    if (kIsWeb) return filePath;
    try {
      final target = '${filePath}_compressed.jpg';
      final result = await FlutterImageCompress.compressAndGetFile(
        filePath,
        target,
        quality: 82,
        minWidth: 1600,
        minHeight: 1600,
      );
      return result?.path ?? filePath;
    } catch (_) {
      return filePath;
    }
  }

  static Future<String?> uploadProofFile({
    required String achievementId,
    required String filePath,
  }) async {
    if (!isSupabaseConfigured()) return null;
    final userId = maybeSupabase()?.auth.currentUser?.id;
    if (userId == null) return null;
    final client = getSupabase();
    final compressed =
        await _compressForUpload(filePath) ?? filePath;
    final ext = 'jpg';
    final fileName =
        '$userId/$achievementId/${DateTime.now().millisecondsSinceEpoch}.$ext';

    try {
      await client.storage
          .from('achievement-proofs')
          .upload(fileName, File(compressed));
      final urlResult = await client.storage
          .from('achievement-proofs')
          .createSignedUrl(fileName, 365 * 24 * 60 * 60);
      return urlResult;
    } catch (_) {
      return null;
    }
  }

  static Future<List<String>> uploadProofFiles({
    required String achievementId,
    required List<String> filePaths,
  }) async {
    final urls = <String>[];
    for (final path in filePaths) {
      final url = await uploadProofFile(
        achievementId: achievementId,
        filePath: path,
      );
      if (url != null) urls.add(url);
    }
    return urls;
  }
}
