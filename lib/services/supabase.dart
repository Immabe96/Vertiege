import 'package:supabase_flutter/supabase_flutter.dart';

SupabaseClient? _client;

Future<SupabaseClient> getSupabase() async {
  if (_client != null) return _client!;
  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL', defaultValue: ''),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: ''),
  );
  _client = Supabase.instance.client;
  return _client!;
}

bool isSupabaseConfigured() {
  final url = const String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  return url.isNotEmpty && url != 'your-supabase-url';
}

SupabaseClient? get supabaseClient => _client;
