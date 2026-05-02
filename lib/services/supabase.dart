import 'package:supabase_flutter/supabase_flutter.dart';

SupabaseClient getSupabase() => Supabase.instance.client;

bool isSupabaseConfigured() {
  final url = const String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  return url.isNotEmpty && url != 'your-supabase-url';
}
