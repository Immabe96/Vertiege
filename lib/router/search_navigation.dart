import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Opens the global search screen (residents + worlds via [ResidentSearchService]).
void openGlobalSearch(BuildContext context, {String? query}) {
  final trimmed = query?.trim();
  if (trimmed != null && trimmed.isNotEmpty) {
    context.push(
      '/search?q=${Uri.encodeComponent(trimmed.startsWith('#') ? trimmed.substring(1) : trimmed)}',
    );
    return;
  }
  context.push('/search');
}
