class RepositoryResult<T> {
  final T? data;
  final Object? error;
  final StackTrace? stackTrace;
  final bool queued;

  const RepositoryResult.success(this.data)
    : error = null,
      stackTrace = null,
      queued = false;

  const RepositoryResult.queued({this.data})
    : error = null,
      stackTrace = null,
      queued = true;

  const RepositoryResult.failure(this.error, [this.stackTrace])
    : data = null,
      queued = false;

  bool get isSuccess => error == null && !queued;
  bool get isFailure => error != null;
}
