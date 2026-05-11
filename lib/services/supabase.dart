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
/// [Supabase.initialize] is called in main() and throws if the URL
/// or anon key is missing, so [Supabase.instance.isInitialized] is
/// a reliable gate.
bool isSupabaseConfigured() {
  return maybeSupabase() != null;
}
