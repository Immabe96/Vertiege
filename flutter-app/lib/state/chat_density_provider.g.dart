// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_density_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ChatDensityNotifier)
final chatDensityProvider = ChatDensityNotifierProvider._();

final class ChatDensityNotifierProvider
    extends $NotifierProvider<ChatDensityNotifier, ChatMessageDensity> {
  ChatDensityNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatDensityProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatDensityNotifierHash();

  @$internal
  @override
  ChatDensityNotifier create() => ChatDensityNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChatMessageDensity value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChatMessageDensity>(value),
    );
  }
}

String _$chatDensityNotifierHash() =>
    r'4570db590167e1ad3fd01cac56eb0d820a5d9f08';

abstract class _$ChatDensityNotifier extends $Notifier<ChatMessageDensity> {
  ChatMessageDensity build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ChatMessageDensity, ChatMessageDensity>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ChatMessageDensity, ChatMessageDensity>,
              ChatMessageDensity,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
