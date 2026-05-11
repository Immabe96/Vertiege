import 'supabase.dart';
import 'secure_storage_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static Future<AuthResponse> signInWithEmail(String email, String password) async {
    final client = getSupabase();
    final response = await client.auth.signInWithPassword(email: email, password: password);
    if (response.session != null) {
      await _persistSession(response.session!);
    }
    return response;
  }

  static Future<AuthResponse> signUpWithEmail(String email, String password) async {
    final client = getSupabase();
    final response = await client.auth.signUp(email: email, password: password);
    if (response.session != null) {
      await _persistSession(response.session!);
    }
    return response;
  }

  static Future<void> signInWithOtp(String email) async {
    final client = getSupabase();
    await client.auth.signInWithOtp(email: email);
  }

  // ── OAuth ────────────────────────────────────────────────

  static Future<bool> signInWithGoogle() async {
    try {
      final client = getSupabase();
      await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'vertiege://auth/callback',
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> signInWithApple() async {
    try {
      final client = getSupabase();
      await client.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: 'vertiege://auth/callback',
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Twin Seal (TOTP) ─────────────────────────────────────

  static Future<Map<String, dynamic>?> generateTwinSeal() async {
    try {
      final client = getSupabase();
      final res = await client.functions.invoke('generate-totp');
      return res.data as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> verifyTwinSeal(String code) async {
    try {
      final client = getSupabase();
      final res = await client.functions.invoke('verify-totp', body: {'code': code});
      return res.data?['valid'] == true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> enrollTwinSeal(String secret, String code) async {
    try {
      final client = getSupabase();
      final res = await client.functions.invoke(
        'enroll-totp',
        body: {'secret': secret, 'code': code},
      );
      return res.data?['enrolled'] == true;
    } catch (_) {
      return false;
    }
  }

  // ── Session utilities ────────────────────────────────────

  static Future<void> _persistSession(Session session) async {
    await SecureStorageService.saveUserId(session.user.id);
    await SecureStorageService.saveTokens(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
    );
  }

  static Future<void> signOut() async {
    final client = getSupabase();
    await client.auth.signOut();
    await SecureStorageService.clearAll();
  }

  static Future<Session?> getSession() async {
    final client = getSupabase();
    return client.auth.currentSession;
  }

  static Future<User?> getCurrentUser() async {
    final client = getSupabase();
    return client.auth.currentUser;
  }

  static Stream<AuthState> onAuthStateChange() {
    return getSupabase().auth.onAuthStateChange;
  }
}
