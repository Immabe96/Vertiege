// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'channel_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ChannelNotifier)
final channelProvider = ChannelNotifierProvider._();

final class ChannelNotifierProvider
    extends $NotifierProvider<ChannelNotifier, ChannelState> {
  ChannelNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'channelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$channelNotifierHash();

  @$internal
  @override
  ChannelNotifier create() => ChannelNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChannelState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChannelState>(value),
    );
  }
}

String _$channelNotifierHash() => r'1d7cd6fe9194fe6887ab2565402ab7d41d3b3a34';

abstract class _$ChannelNotifier extends $Notifier<ChannelState> {
  ChannelState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ChannelState, ChannelState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ChannelState, ChannelState>,
              ChannelState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
