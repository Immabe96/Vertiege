// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(EventNotifier)
final eventProvider = EventNotifierProvider._();

final class EventNotifierProvider
    extends $NotifierProvider<EventNotifier, EventState> {
  EventNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'eventProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$eventNotifierHash();

  @$internal
  @override
  EventNotifier create() => EventNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EventState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EventState>(value),
    );
  }
}

String _$eventNotifierHash() => r'ce154bf26b03a2f2e98666ce825a21c9f8876fea';

abstract class _$EventNotifier extends $Notifier<EventState> {
  EventState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<EventState, EventState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<EventState, EventState>,
              EventState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
