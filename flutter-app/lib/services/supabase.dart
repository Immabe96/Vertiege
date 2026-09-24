import 'package:supabase_flutter/supabase_flutter.dart';

SupabaseClient getSupabase() => Supabase.instance.client;

SupabaseClient? maybeSupabase() {
  try {
    if (!Supabase.instance.isInitialized) return null;
    return Supabase.instance.client;
  } catch (_) {
    return null;
  }
}

/// Checks whether Supabase is configured by inspecting the actual
/// [Supabase] instance that was initialized in main.dart from .env
/// values, rather than relying on compile-time constants
/// (String.fromEnvironment), which would always be empty when
/// credentials come from flutter_dotenv.
///
/// [Supabase.initialize] is called from [SupabaseBootstrap.initialize]
/// in `main.dart` before `runApp` when `.env` is present in the asset bundle.
/// Auth screens may call [SupabaseBootstrap.ensureReady] to retry after a failed boot.
bool isSupabaseConfigured() {
  return maybeSupabase() != null;
}
