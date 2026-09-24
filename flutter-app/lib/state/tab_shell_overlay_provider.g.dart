// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tab_shell_overlay_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Blocks tab-shell chrome (compose FAB) while sheets/modals are open.

@ProviderFor(TabShellOverlayNotifier)
final tabShellOverlayProvider = TabShellOverlayNotifierProvider._();

/// Blocks tab-shell chrome (compose FAB) while sheets/modals are open.
final class TabShellOverlayNotifierProvider
    extends $NotifierProvider<TabShellOverlayNotifier, int> {
  /// Blocks tab-shell chrome (compose FAB) while sheets/modals are open.
  TabShellOverlayNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tabShellOverlayProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tabShellOverlayNotifierHash();

  @$internal
  @override
  TabShellOverlayNotifier create() => TabShellOverlayNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$tabShellOverlayNotifierHash() =>
    r'eb0d57fe46853819f98ee886fc243c14f3ba641a';

/// Blocks tab-shell chrome (compose FAB) while sheets/modals are open.

abstract class _$TabShellOverlayNotifier extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
