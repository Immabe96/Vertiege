// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quest_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(QuestNotifier)
final questProvider = QuestNotifierProvider._();

final class QuestNotifierProvider
    extends $NotifierProvider<QuestNotifier, QuestState> {
  QuestNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'questProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$questNotifierHash();

  @$internal
  @override
  QuestNotifier create() => QuestNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(QuestState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<QuestState>(value),
    );
  }
}

String _$questNotifierHash() => r'd4ebf8b6c2a5a7bcf5410dd769e6b46115a7d42f';

abstract class _$QuestNotifier extends $Notifier<QuestState> {
  QuestState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<QuestState, QuestState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<QuestState, QuestState>,
              QuestState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
