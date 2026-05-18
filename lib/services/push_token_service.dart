import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'firebase_bootstrap.dart';
import 'supabase.dart';

class PushTokenService {
  PushTokenService._();

  static Future<void> registerForResident(String residentId) async {
    if (!FirebaseBootstrap.isInitialized || kIsWeb || !isSupabaseConfigured()) {
      return;
    }

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();
    final token = await messaging.getToken();
    if (token == null || token.isEmpty) return;

    await getSupabase().from('device_tokens').upsert({
      'resident_id': residentId,
      'token': token,
      'platform': defaultTargetPlatform.name,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'token');
  }
}
