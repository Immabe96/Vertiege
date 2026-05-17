import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage wrapper for sensitive data (auth tokens, user ID, etc.).
/// Uses platform-native secure storage (Keychain on iOS, EncryptedSharedPrefs on Android).
class SecureStorageService {
  SecureStorageService._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // ── Keys ──────────────────────────────────────────────────
  static const String userIdKey = '@secure_user_id';
  static const String sessionTokenKey = '@secure_session_token';
  static const String refreshTokenKey = '@secure_refresh_token';

  // ── Read / Write ──────────────────────────────────────────

  static Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (_) {
      return null;
    }
  }

  static Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (_) {
      // Silently fail — secure storage may not be available on all platforms
    }
  }

  static Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (_) {}
  }

  // ── Convenience methods ───────────────────────────────────

  /// Store the current user's ID after successful auth.
  static Future<void> saveUserId(String userId) => write(userIdKey, userId);

  /// Retrieve stored user ID (for offline session restore).
  static Future<String?> getUserId() => read(userIdKey);

  /// Store session tokens after auth.
  static Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    await write(sessionTokenKey, accessToken);
    if (refreshToken != null) {
      await write(refreshTokenKey, refreshToken);
    }
  }

  /// Clear all secure data on sign-out.
  static Future<void> clearAll() async {
    await delete(userIdKey);
    await delete(sessionTokenKey);
    await delete(refreshTokenKey);
  }
}
