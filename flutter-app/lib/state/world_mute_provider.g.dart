// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'world_mute_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(WorldMuteNotifier)
final worldMuteProvider = WorldMuteNotifierProvider._();

final class WorldMuteNotifierProvider
    extends $NotifierProvider<WorldMuteNotifier, Set<String>> {
  WorldMuteNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'worldMuteProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$worldMuteNotifierHash();

  @$internal
  @override
  WorldMuteNotifier create() => WorldMuteNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<String>>(value),
    );
  }
}

String _$worldMuteNotifierHash() => r'05f1fea90b7f1e291e4cd6910c023204e230ac52';

abstract class _$WorldMuteNotifier extends $Notifier<Set<String>> {
  Set<String> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<Set<String>, Set<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Set<String>, Set<String>>,
              Set<String>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
