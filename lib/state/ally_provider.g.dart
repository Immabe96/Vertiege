// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ally_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AllyNotifier)
final allyProvider = AllyNotifierProvider._();

final class AllyNotifierProvider
    extends $NotifierProvider<AllyNotifier, AllyState> {
  AllyNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'allyProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$allyNotifierHash();

  @$internal
  @override
  AllyNotifier create() => AllyNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AllyState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AllyState>(value),
    );
  }
}

String _$allyNotifierHash() => r'e04ec2c7326780ed5b547feed30fb97196f5b1d9';

abstract class _$AllyNotifier extends $Notifier<AllyState> {
  AllyState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AllyState, AllyState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AllyState, AllyState>,
              AllyState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
