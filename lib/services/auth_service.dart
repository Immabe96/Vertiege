import 'supabase.dart';

class AuthService {
  static Future<AuthResponse> signInWithEmail(String email, String password) async {
    final client = getSupabase();
    return client.auth.signInWithPassword(email: email, password: password);
  }

  static Future<AuthResponse> signUpWithEmail(String email, String password) async {
    final client = getSupabase();
    return client.auth.signUp(email: email, password: password);
  }

  static Future<void> signInWithOtp(String email) async {
    final client = getSupabase();
    await client.auth.signInWithOtp(email: email);
  }

  static Future<void> signOut() async {
    final client = getSupabase();
    await client.auth.signOut();
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
