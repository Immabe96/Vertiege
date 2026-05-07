import 'supabase.dart';
import 'secure_storage_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static Future<AuthResponse> signInWithEmail(String email, String password) async {
    final client = getSupabase();
    final response = await client.auth.signInWithPassword(email: email, password: password);
    if (response.session != null) {
      await SecureStorageService.saveUserId(response.user?.id ?? '');
      await SecureStorageService.saveTokens(
        accessToken: response.session!.accessToken,
        refreshToken: response.session!.refreshToken,
      );
    }
    return response;
  }

  static Future<AuthResponse> signUpWithEmail(String email, String password) async {
    final client = getSupabase();
    final response = await client.auth.signUp(email: email, password: password);
    if (response.session != null) {
      await SecureStorageService.saveUserId(response.user?.id ?? '');
      await SecureStorageService.saveTokens(
        accessToken: response.session!.accessToken,
        refreshToken: response.session!.refreshToken,
      );
    }
    return response;
  }

  static Future<void> signInWithOtp(String email) async {
    final client = getSupabase();
    await client.auth.signInWithOtp(email: email);
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
