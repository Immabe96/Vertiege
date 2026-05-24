import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/supabase.dart';
import '../services/supabase_bootstrap.dart';

/// Whether Supabase finished initializing (or was already ready).
final supabaseBootstrapProvider = Provider<SupabaseBootstrapResult>((ref) {
  if (maybeSupabase() != null) {
    return SupabaseBootstrapResult.ready;
  }
  return SupabaseBootstrap.lastResult;
});
