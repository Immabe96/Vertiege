import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Platform secure key-value store (Keychain / EncryptedSharedPreferences).
///
/// Auth sessions are owned by [Supabase] — do not duplicate access/refresh
/// tokens here. Use this for app-specific secrets (e.g. TOTP) when needed.
class SecureStorageService {
  SecureStorageService._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // Legacy keys from pre-F27 auth mirroring (cleared on sign-out).
  static const String _legacyUserIdKey = '@secure_user_id';
  static const String _legacySessionTokenKey = '@secure_session_token';
  static const String _legacyRefreshTokenKey = '@secure_refresh_token';

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
      // Secure storage may be unavailable on some platforms.
    }
  }

  static Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (_) {}
  }

  /// Removes duplicated auth credentials written before F27.
  static Future<void> clearLegacyAuthCredentials() async {
    await delete(_legacyUserIdKey);
    await delete(_legacySessionTokenKey);
    await delete(_legacyRefreshTokenKey);
  }
}
