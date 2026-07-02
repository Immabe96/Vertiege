// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PostNotifier)
final postProvider = PostNotifierProvider._();

final class PostNotifierProvider
    extends $NotifierProvider<PostNotifier, PostState> {
  PostNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'postProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$postNotifierHash();

  @$internal
  @override
  PostNotifier create() => PostNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PostState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PostState>(value),
    );
  }
}

String _$postNotifierHash() => r'3a3b373b78350172363208403262cdbefdd62b8d';

abstract class _$PostNotifier extends $Notifier<PostState> {
  PostState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<PostState, PostState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PostState, PostState>,
              PostState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
