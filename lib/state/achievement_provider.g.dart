// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'achievement_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AchievementNotifier)
final achievementProvider = AchievementNotifierProvider._();

final class AchievementNotifierProvider
    extends $NotifierProvider<AchievementNotifier, AchievementState> {
  AchievementNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'achievementProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$achievementNotifierHash();

  @$internal
  @override
  AchievementNotifier create() => AchievementNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AchievementState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AchievementState>(value),
    );
  }
}

String _$achievementNotifierHash() =>
    r'8e5ce662c011649e245a84a6a9666abf122c5f16';

abstract class _$AchievementNotifier extends $Notifier<AchievementState> {
  AchievementState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AchievementState, AchievementState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AchievementState, AchievementState>,
              AchievementState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
