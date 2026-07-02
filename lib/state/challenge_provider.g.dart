// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'challenge_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ChallengeNotifier)
final challengeProvider = ChallengeNotifierProvider._();

final class ChallengeNotifierProvider
    extends $NotifierProvider<ChallengeNotifier, ChallengeState> {
  ChallengeNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'challengeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$challengeNotifierHash();

  @$internal
  @override
  ChallengeNotifier create() => ChallengeNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChallengeState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChallengeState>(value),
    );
  }
}

String _$challengeNotifierHash() => r'e9cb52f8b0c1e10d2651fecb88acb156a351daff';

abstract class _$ChallengeNotifier extends $Notifier<ChallengeState> {
  ChallengeState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ChallengeState, ChallengeState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ChallengeState, ChallengeState>,
              ChallengeState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
