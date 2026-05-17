import 'dart:io';
import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/io_client.dart' as http_io;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'screens/onboarding/the_gate_screen.dart';
import 'services/crash_reporter.dart';

bool _handlingFlutterError = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    if (_handlingFlutterError) return;
    _handlingFlutterError = true;
    try {
      CrashReporter.instance.recordError(details.exception, details.stack ?? StackTrace.current);
    } finally {
      _handlingFlutterError = false;
    }
  };
  PlatformDispatcher.instance.onError = (error, st) {
    CrashReporter.instance.recordError(error, st);
    return true;
  };

  await dotenv.load(fileName: '.env');
  await loadGateCompletionStatus();

  final url = dotenv.env['SUPABASE_URL'] ?? '';
  final anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  if (url.isEmpty || anonKey.isEmpty) {
    debugPrint('Missing Supabase credentials — running in offline mode');
    runApp(const ProviderScope(child: VirtualStatusWorldsApp()));
    return;
  }

  // Create HTTP client with full timeout: connection + idle.
  // connectionTimeout = TCP handshake deadline
  // idleTimeout = max time waiting for server response after connecting
  final httpClient = http_io.IOClient(
    HttpClient()
      ..connectionTimeout = const Duration(seconds: 5)
      ..idleTimeout = const Duration(seconds: 10),
  );

  await Supabase.initialize(url: url, anonKey: anonKey, httpClient: httpClient);

  runApp(const ProviderScope(child: VirtualStatusWorldsApp()));
}
