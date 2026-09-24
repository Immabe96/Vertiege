/// UI state for any async data load.
///
/// Replaces ad-hoc loading/error/empty booleans spread across providers.
enum LoadStateStatus { initial, loading, loaded, empty, error }

class LoadState<T> {
  final LoadStateStatus status;
  final T? data;
  final Object? error;
  final StackTrace? stackTrace;

  // ignore: unused_element
  const LoadState._({
    required this.status,
    this.data,
    this.error,
    this.stackTrace,
  });

  const LoadState.initial()
      : status = LoadStateStatus.initial,
        data = null,
        error = null,
        stackTrace = null;

  const LoadState.loading({this.data})
      : status = LoadStateStatus.loading,
        error = null,
        stackTrace = null;

  const LoadState.loaded(T this.data)
      : status = LoadStateStatus.loaded,
        error = null,
        stackTrace = null;

  const LoadState.empty()
      : status = LoadStateStatus.empty,
        data = null,
        error = null,
        stackTrace = null;

  const LoadState.error(Object this.error, [this.stackTrace])
      : status = LoadStateStatus.error,
        data = null;

  bool get isLoading => status == LoadStateStatus.loading;
  bool get isLoaded => status == LoadStateStatus.loaded;
  bool get isEmpty => status == LoadStateStatus.empty;
  bool get hasError => status == LoadStateStatus.error;
  bool get isInitial => status == LoadStateStatus.initial;

  T? get valueOrNull => data;

  R fold<R>({
    required R Function() initial,
    required R Function(T? previous) loading,
    required R Function(T data) loaded,
    required R Function() empty,
    required R Function(Object error, StackTrace? stackTrace) error,
  }) {
    return switch (status) {
      LoadStateStatus.initial => initial(),
      LoadStateStatus.loading => loading(data),
      LoadStateStatus.loaded => loaded(data as T),
      LoadStateStatus.empty => empty(),
      LoadStateStatus.error => error(this.error!, stackTrace),
    };
  }
}
