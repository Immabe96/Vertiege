// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'commune_shell_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Current matched path from [GoRouter] (refreshes on navigation).

@ProviderFor(routerPath)
final routerPathProvider = RouterPathProvider._();

/// Current matched path from [GoRouter] (refreshes on navigation).

final class RouterPathProvider
    extends $FunctionalProvider<String, String, String>
    with $Provider<String> {
  /// Current matched path from [GoRouter] (refreshes on navigation).
  RouterPathProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'routerPathProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$routerPathHash();

  @$internal
  @override
  $ProviderElement<String> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String create(Ref ref) {
    return routerPath(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$routerPathHash() => r'6dd0d3c899ce81eb4f03fd9907b28aefc2379623';

/// True when bottom tab bar should be hidden (immersive chat / voice).

@ProviderFor(hideBottomNav)
final hideBottomNavProvider = HideBottomNavProvider._();

/// True when bottom tab bar should be hidden (immersive chat / voice).

final class HideBottomNavProvider extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// True when bottom tab bar should be hidden (immersive chat / voice).
  HideBottomNavProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'hideBottomNavProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$hideBottomNavHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return hideBottomNav(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$hideBottomNavHash() => r'f94e6f525e39cc7330210c0de2899bc2be3b629a';
