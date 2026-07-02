// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'resident_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ResidentNotifier)
final residentProvider = ResidentNotifierProvider._();

final class ResidentNotifierProvider
    extends $NotifierProvider<ResidentNotifier, ResidentState> {
  ResidentNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'residentProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$residentNotifierHash();

  @$internal
  @override
  ResidentNotifier create() => ResidentNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ResidentState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ResidentState>(value),
    );
  }
}

String _$residentNotifierHash() => r'a38659dbe3cb6a480b425e3470aec50be823a4c4';

abstract class _$ResidentNotifier extends $Notifier<ResidentState> {
  ResidentState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ResidentState, ResidentState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ResidentState, ResidentState>,
              ResidentState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Side-effect listener — must not run inside [ResidentNotifier.build] (self-dependency).

@ProviderFor(residentMilestoneListener)
final residentMilestoneListenerProvider = ResidentMilestoneListenerProvider._();

/// Side-effect listener — must not run inside [ResidentNotifier.build] (self-dependency).

final class ResidentMilestoneListenerProvider
    extends $FunctionalProvider<void, void, void>
    with $Provider<void> {
  /// Side-effect listener — must not run inside [ResidentNotifier.build] (self-dependency).
  ResidentMilestoneListenerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'residentMilestoneListenerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$residentMilestoneListenerHash();

  @$internal
  @override
  $ProviderElement<void> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  void create(Ref ref) {
    return residentMilestoneListener(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$residentMilestoneListenerHash() =>
    r'6c755ed80a8730f456fc5c0a3093ef60598569e8';
