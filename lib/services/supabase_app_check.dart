import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

import 'app_check_service.dart';
import 'firebase_bootstrap.dart';

/// Optional Firebase App Check token for Supabase edge/RPC hardening (Wave 21).
abstract final class SupabaseAppCheck {
  static Future<String?> token() async {
    if (kIsWeb || !FirebaseBootstrap.isInitialized || !AppCheckService.isActivated) {
      return null;
    }
    try {
      return await FirebaseAppCheck.instance.getToken();
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, String>> headers() async {
    final value = await token();
    if (value == null || value.isEmpty) return const {};
    return {'X-Firebase-AppCheck': value};
  }
}
