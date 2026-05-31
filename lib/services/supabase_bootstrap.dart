import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/io_client.dart' as http_io;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'crash_reporter.dart';

/// Result of [SupabaseBootstrap.initialize].
enum SupabaseBootstrapResult {
  pending,
  ready,
  missingConfig,
  failed,
}

/// Initializes Supabase from `.env` (bundled asset or local file).
abstract final class SupabaseBootstrap {
  static SupabaseBootstrapResult _lastResult = SupabaseBootstrapResult.pending;
  static bool _initialized = false;

  static SupabaseBootstrapResult get lastResult => _lastResult;

  static bool get isReady =>
      _initialized && _lastResult == SupabaseBootstrapResult.ready;

  static Future<SupabaseBootstrapResult> initialize() async {
    if (_initialized && _lastResult == SupabaseBootstrapResult.ready) {
      return _lastResult;
    }

    final url = dotenv.env['SUPABASE_URL']?.trim() ?? '';
    final anonKey = dotenv.env['SUPABASE_ANON_KEY']?.trim() ?? '';
    if (url.isEmpty || anonKey.isEmpty) {
      debugPrint(
        'SupabaseBootstrap: missing SUPABASE_URL or SUPABASE_ANON_KEY in .env',
      );
      _lastResult = SupabaseBootstrapResult.missingConfig;
      return _lastResult;
    }

    try {
      final httpClient = http_io.IOClient(
        HttpClient()
          ..connectionTimeout = const Duration(seconds: 8)
          ..idleTimeout = const Duration(seconds: 15),
      );
      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
        httpClient: httpClient,
      ).timeout(const Duration(seconds: 15));
      _initialized = true;
      _lastResult = SupabaseBootstrapResult.ready;
      debugPrint('SupabaseBootstrap: ready');
      return _lastResult;
    } catch (e, st) {
      debugPrint('SupabaseBootstrap: failed — $e');
      CrashReporter.instance.recordError(
        e,
        st,
        hint: 'supabase bootstrap main',
      );
      _lastResult = SupabaseBootstrapResult.failed;
      return _lastResult;
    }
  }
}
