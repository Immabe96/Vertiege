import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// Root tab screen chrome: [FScaffold] + [FHeader] (matches [VHubPage] hub layout).
class VTabPage extends StatelessWidget {
  final String? title;
  final Widget? titleWidget;
  final Widget? header;
  final List<Widget> headerActions;
  final Widget body;
  final Widget? footer;

  const VTabPage({
    super.key,
    this.title,
    this.titleWidget,
    this.header,
    this.headerActions = const [],
    required this.body,
    this.footer,
  }) : assert(
          header != null || titleWidget != null || title != null,
          'Provide header, titleWidget, or title',
        );

  @override
  Widget build(BuildContext context) {
    final resolvedHeader = header ??
        FHeader(
          title: titleWidget ?? Text(title!),
          suffixes: headerActions,
        );

    return FScaffold(
      header: resolvedHeader,
      footer: footer,
      child: Material(
        type: MaterialType.transparency,
        child: body,
      ),
    );
  }
}
