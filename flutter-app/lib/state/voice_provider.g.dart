// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'voice_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(VoiceNotifier)
final voiceProvider = VoiceNotifierProvider._();

final class VoiceNotifierProvider
    extends $NotifierProvider<VoiceNotifier, VoiceState> {
  VoiceNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'voiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$voiceNotifierHash();

  @$internal
  @override
  VoiceNotifier create() => VoiceNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VoiceState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VoiceState>(value),
    );
  }
}

String _$voiceNotifierHash() => r'2804841bf4872b90b32f51f5cf805f2f7a843f78';

abstract class _$VoiceNotifier extends $Notifier<VoiceState> {
  VoiceState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<VoiceState, VoiceState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<VoiceState, VoiceState>,
              VoiceState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
