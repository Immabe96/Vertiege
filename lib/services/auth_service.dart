import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../state/session_reset.dart';
import 'analytics_events.dart';
import 'analytics_service.dart';
import 'crash_reporter.dart';
import 'secure_storage_service.dart';
import 'supabase.dart';
import 'verifier_session.dart';

class AuthService {
  static SupabaseClient _requireClient() {
    final client = maybeSupabase();
    if (client == null) {
      throw const AuthException(
        'Authentication is unavailable because Supabase is not configured.',
      );
    }
    return client;
  }

  static const _oauthRedirect = 'vertiege://auth/callback';

  static Future<AuthResponse> signInWithEmail(
    String email,
    String password,
  ) async {
    final client = _requireClient();
    final response = await client.auth
        .signInWithPassword(
          email: email,
          password: password,
        )
        .timeout(const Duration(seconds: 20));
    return response;
  }

  static Future<AuthResponse> signUpWithEmail(
    String email,
    String password,
  ) async {
    final client = _requireClient();
    final response = await client.auth.signUp(email: email, password: password);
    return response;
  }

  static Future<void> signInWithOtp(String email) async {
    final client = _requireClient();
    await client.auth.signInWithOtp(email: email);
  }

  // ── OAuth ────────────────────────────────────────────────

  static Future<bool> signInWithGoogle() async {
    return _signInWithOAuth(OAuthProvider.google, hint: 'Google OAuth signIn');
  }

  static Future<bool> signInWithApple() async {
    return _signInWithOAuth(OAuthProvider.apple, hint: 'Apple OAuth signIn');
  }

  static Future<bool> _signInWithOAuth(
    OAuthProvider provider, {
    required String hint,
  }) async {
    try {
      final client = _requireClient();
      final launched = await client.auth.signInWithOAuth(
        provider,
        redirectTo: _oauthRedirect,
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
      return launched;
    } catch (e, st) {
      CrashReporter.instance.recordError(e, st, hint: hint);
      rethrow;
    }
  }

  // ── Twin Seal (TOTP) ─────────────────────────────────────

  static Future<Map<String, dynamic>?> generateTwinSeal() async {
    try {
      final client = _requireClient();
      final res = await client.functions.invoke('generate-totp');
      return res.data as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> verifyTwinSeal(String code) async {
    try {
      final client = _requireClient();
      final res = await client.functions.invoke(
        'verify-totp',
        body: {'code': code},
      );
      return res.data?['valid'] == true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> enrollTwinSeal(String secret, String code) async {
    try {
      final client = _requireClient();
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

  static Future<void> signOut({WidgetRef? ref}) async {
    VerifierSession.exit();
    final client = maybeSupabase();
    if (client != null) {
      await client.auth.signOut();
    }
    await SecureStorageService.clearLegacyAuthCredentials();
    await clearUserPersistedSessionData();
    if (ref != null) {
      resetUserSessionState(ref);
    }
    unawaited(AnalyticsService.logEvent(AnalyticsEvents.signOut));
    CrashReporter.instance.setUser('', name: null);
  }

  static Future<Session?> getSession() async {
    return maybeSupabase()?.auth.currentSession;
  }

  static Future<User?> getCurrentUser() async {
    return maybeSupabase()?.auth.currentUser;
  }

  static Stream<AuthState> onAuthStateChange() {
    final client = _requireClient();
    return client.auth.onAuthStateChange;
  }
}
