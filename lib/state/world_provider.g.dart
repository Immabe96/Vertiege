// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'world_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(WorldNotifier)
final worldProvider = WorldNotifierProvider._();

final class WorldNotifierProvider
    extends $NotifierProvider<WorldNotifier, WorldState> {
  WorldNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'worldProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$worldNotifierHash();

  @$internal
  @override
  WorldNotifier create() => WorldNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WorldState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WorldState>(value),
    );
  }
}

String _$worldNotifierHash() => r'03e0c6b0faf0fd9541219d84ee94b70bcbe25473';

abstract class _$WorldNotifier extends $Notifier<WorldState> {
  WorldState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<WorldState, WorldState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<WorldState, WorldState>,
              WorldState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
