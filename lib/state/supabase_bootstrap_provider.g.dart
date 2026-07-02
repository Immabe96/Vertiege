// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'supabase_bootstrap_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether Supabase finished initializing (or was already ready).

@ProviderFor(supabaseBootstrap)
final supabaseBootstrapProvider = SupabaseBootstrapProvider._();

/// Whether Supabase finished initializing (or was already ready).

final class SupabaseBootstrapProvider
    extends
        $FunctionalProvider<
          SupabaseBootstrapResult,
          SupabaseBootstrapResult,
          SupabaseBootstrapResult
        >
    with $Provider<SupabaseBootstrapResult> {
  /// Whether Supabase finished initializing (or was already ready).
  SupabaseBootstrapProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'supabaseBootstrapProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$supabaseBootstrapHash();

  @$internal
  @override
  $ProviderElement<SupabaseBootstrapResult> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SupabaseBootstrapResult create(Ref ref) {
    return supabaseBootstrap(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SupabaseBootstrapResult value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SupabaseBootstrapResult>(value),
    );
  }
}

String _$supabaseBootstrapHash() => r'eff79718b3b0c9318ee02bb7f7ddfd2f9345d305';
