import 'dart:io';

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

  static Future<String?> uploadProofFile({
    required String achievementId,
    required String filePath,
  }) async {
    if (!isSupabaseConfigured()) return null;
    final userId = maybeSupabase()?.auth.currentUser?.id;
    if (userId == null) return null;
    final client = getSupabase();
    final ext = filePath.split('.').last.toLowerCase();
    final fileName =
        '$userId/$achievementId/${DateTime.now().millisecondsSinceEpoch}.$ext';

    try {
      await client.storage
          .from('achievement-proofs')
          .upload(fileName, File(filePath));
      final urlResult = await client.storage
          .from('achievement-proofs')
          .createSignedUrl(fileName, 365 * 24 * 60 * 60);
      return urlResult;
    } catch (_) {
      return null;
    }
  }
}
