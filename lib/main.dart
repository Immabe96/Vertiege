import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'theme/theme_prefs.dart';
import 'services/supabase_bootstrap.dart';
import 'services/crash_reporter.dart';
import 'services/firebase_messaging_handlers.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

bool _handlingFlutterError = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  FlutterError.onError = (details) {
    if (_handlingFlutterError) return;
    _handlingFlutterError = true;
    try {
      CrashReporter.instance.recordError(
        details.exception,
        details.stack ?? StackTrace.current,
      );
    } finally {
      _handlingFlutterError = false;
    }
  };
  PlatformDispatcher.instance.onError = (error, st) {
    CrashReporter.instance.recordError(error, st);
    return true;
  };

  await dotenv.load(fileName: '.env', isOptional: true);
  await SupabaseBootstrap.initialize();
  await ThemePrefs.warmCache();

  // Show Flutter UI immediately — Firebase/Supabase init runs after first frame.
  runApp(const ProviderScope(child: VirtualStatusWorldsApp()));
}
