import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart' as http_io;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_check_service.dart';
import 'crash_reporter.dart';
import 'supabase_app_check.dart';

/// Result of [SupabaseBootstrap.initialize].
enum SupabaseBootstrapResult {
  pending,
  ready,
  missingConfig,
  failed,
}

/// [http.Client] that injects Firebase App Check tokens into outgoing
/// Supabase requests. Gracefully degrades when App Check is unavailable.
class _AppCheckClient extends http.BaseClient {
  _AppCheckClient(this._inner);

  final http.Client _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (AppCheckService.isActivated) {
      final token = await SupabaseAppCheck.token();
      if (token != null) {
        request.headers['X-Firebase-AppCheck'] = token;
      }
    }
    return _inner.send(request);
  }
}

/// Initializes Supabase from `.env` (bundled asset or local file).
abstract final class SupabaseBootstrap {
  static SupabaseBootstrapResult _lastResult = SupabaseBootstrapResult.pending;
  static bool _initialized = false;
  static Future<SupabaseBootstrapResult>? _initFuture;

  static SupabaseBootstrapResult get lastResult => _lastResult;

  static bool get isReady =>
      _initialized && _lastResult == SupabaseBootstrapResult.ready;

  /// User-facing message when cloud auth/data is unavailable.
  static String? messageFor(SupabaseBootstrapResult result) {
    return switch (result) {
      SupabaseBootstrapResult.ready => null,
      SupabaseBootstrapResult.missingConfig =>
        'Cloud sign-in is not configured in this build (.env missing in APK).',
      SupabaseBootstrapResult.failed =>
        'Could not connect to cloud. Check network and try again.',
      SupabaseBootstrapResult.pending => 'Connecting to cloud…',
    };
  }

  /// Idempotent — safe from main(), auth screens, and app bootstrap.
  static Future<bool> ensureReady() async {
    if (isReady) return true;
    try {
      if (Supabase.instance.isInitialized) {
        _initialized = true;
        _lastResult = SupabaseBootstrapResult.ready;
        return true;
      }
    } catch (_) {}
    return (await initialize()) == SupabaseBootstrapResult.ready;
  }

  static Future<SupabaseBootstrapResult> initialize() async {
    if (_initFuture != null) return _initFuture!;
    if (_initialized && _lastResult == SupabaseBootstrapResult.ready) {
      return _lastResult;
    }
    _initFuture = _doInitialize();
    return _initFuture!;
  }

  static Future<SupabaseBootstrapResult> _doInitialize() async {

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
      final httpClient = _AppCheckClient(http_io.IOClient(
        HttpClient()
          ..connectionTimeout = const Duration(seconds: 8)
          ..idleTimeout = const Duration(seconds: 15),
      ));
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
