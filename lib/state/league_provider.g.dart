// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'league_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(LeagueNotifier)
final leagueProvider = LeagueNotifierProvider._();

final class LeagueNotifierProvider
    extends $NotifierProvider<LeagueNotifier, LeagueState> {
  LeagueNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'leagueProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$leagueNotifierHash();

  @$internal
  @override
  LeagueNotifier create() => LeagueNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LeagueState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LeagueState>(value),
    );
  }
}

String _$leagueNotifierHash() => r'7fc1cf12c59f752050aaf039a689ed4a6efe7148';

abstract class _$LeagueNotifier extends $Notifier<LeagueState> {
  LeagueState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<LeagueState, LeagueState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LeagueState, LeagueState>,
              LeagueState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
