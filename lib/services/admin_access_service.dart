import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase.dart';

/// Who may use the verifier-only portal (`/verifier/*`).
class AdminAccessService {
  AdminAccessService._();

  static bool isVerifierUser(User? user) {
    if (user == null) return false;

    final appMeta = user.appMetadata;
    if (appMeta['is_verifier'] == true) return true;
    if (appMeta['role'] == 'verifier' || appMeta['role'] == 'super_admin') {
      return true;
    }

    final email = user.email?.trim().toLowerCase();
    if (email == null || email.isEmpty) return false;

    for (final allowed in _verifierEmailsFromEnv()) {
      if (email == allowed) return true;
    }

    return false;
  }

  static bool isCurrentSessionVerifier() {
    final client = maybeSupabase();
    if (client == null) return false;
    return isVerifierUser(client.auth.currentUser);
  }

  /// Bypass XP tier gates (create world, etc.).
  static bool isSuperuser(User? user) {
    if (user == null) return false;

    final appMeta = user.appMetadata;
    if (appMeta['is_superuser'] == true) return true;
    if (appMeta['role'] == 'super_admin' || appMeta['role'] == 'superuser') {
      return true;
    }

    final email = user.email?.trim().toLowerCase();
    if (email == null || email.isEmpty) return false;

    const bootstrap = 'ltyl.naughty@gmail.com';
    if (email == bootstrap) return true;

    for (final allowed in _superuserEmailsFromEnv()) {
      if (email == allowed) return true;
    }

    return false;
  }

  static bool isCurrentSessionSuperuser() {
    final client = maybeSupabase();
    if (client == null) return false;
    return isSuperuser(client.auth.currentUser);
  }

  /// High Roller (tier 2+) or superuser.
  static bool canCreateWorld({required int tierValue}) {
    if (isCurrentSessionSuperuser()) return true;
    return tierValue >= 2;
  }

  static Set<String> _superuserEmailsFromEnv() {
    final raw = dotenv.env['SUPERUSER_EMAILS'] ?? '';
    if (raw.trim().isEmpty) return {};
    return raw
        .split(',')
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toSet();
  }

  static Set<String> _verifierEmailsFromEnv() {
    final raw = dotenv.env['VERIFIER_ADMIN_EMAILS'] ?? '';
    if (raw.trim().isEmpty) return {};
    return raw
        .split(',')
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toSet();
  }
}
