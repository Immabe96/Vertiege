import 'package:flutter/material.dart';
import 'empty_state.dart';
import 'loading_state.dart';

class SafeAsyncBuilder<T> extends StatelessWidget {
  final bool isLoading;
  final bool hasError;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final T? data;
  final Widget Function(T data) builder;
  final Widget? loadingWidget;
  final Widget? errorWidget;
  final bool showDataWhileLoading;

  const SafeAsyncBuilder({
    super.key,
    required this.isLoading,
    required this.hasError,
    this.errorMessage,
    this.onRetry,
    this.data,
    required this.builder,
    this.loadingWidget,
    this.errorWidget,
    this.showDataWhileLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (hasError) {
      return errorWidget ??
          AppErrorState(
            message: errorMessage,
            onRetry: onRetry,
          );
    }

    if (isLoading && (!showDataWhileLoading || data == null)) {
      return loadingWidget ?? const GlassLoadingList(itemCount: 6);
    }

    if (data != null) {
      return builder(data as T);
    }

    return AppErrorState(
      message: 'No data available',
      onRetry: onRetry,
    );
  }
}
