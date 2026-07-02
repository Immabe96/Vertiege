// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favorite_channel_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(FavoriteChannelNotifier)
final favoriteChannelProvider = FavoriteChannelNotifierProvider._();

final class FavoriteChannelNotifierProvider
    extends
        $NotifierProvider<FavoriteChannelNotifier, Map<String, Set<String>>> {
  FavoriteChannelNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'favoriteChannelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$favoriteChannelNotifierHash();

  @$internal
  @override
  FavoriteChannelNotifier create() => FavoriteChannelNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, Set<String>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, Set<String>>>(value),
    );
  }
}

String _$favoriteChannelNotifierHash() =>
    r'b6c78f296325ae705e2e525f34530e7a510beeeb';

abstract class _$FavoriteChannelNotifier
    extends $Notifier<Map<String, Set<String>>> {
  Map<String, Set<String>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<Map<String, Set<String>>, Map<String, Set<String>>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Map<String, Set<String>>, Map<String, Set<String>>>,
              Map<String, Set<String>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
