import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../services/supabase.dart';
import '../services/supabase_bootstrap.dart';

part 'supabase_bootstrap_provider.g.dart';

/// Whether Supabase finished initializing (or was already ready).
@Riverpod(name: 'supabaseBootstrapProvider', keepAlive: true)
SupabaseBootstrapResult supabaseBootstrap(Ref ref) {
  if (maybeSupabase() != null) {
    return SupabaseBootstrapResult.ready;
  }
  return SupabaseBootstrap.lastResult;
}
