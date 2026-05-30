import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

/// Hub-style sub-page: [FScaffold] + [FHeader] (Forui / shadcn layout).
class VHubPage extends StatelessWidget {
  final String title;
  /// When set, replaces the default [Text] title (e.g. inline search field).
  final Widget? titleWidget;
  final Widget body;
  final bool showBack;
  final List<Widget> headerActions;
  final Widget? footer;

  const VHubPage({
    super.key,
    required this.title,
    this.titleWidget,
    required this.body,
    this.showBack = false,
    this.headerActions = const [],
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final titleContent = titleWidget ?? Text(title);
    final header = showBack
        ? FHeader.nested(
            title: titleContent,
            prefixes: [
              FHeaderAction(
                icon: const Icon(FIcons.chevronLeft),
                onPress: () {
                  if (context.canPop()) {
                    context.pop();
                  }
                },
              ),
            ],
            suffixes: headerActions,
          )
        : FHeader(
            title: titleContent,
            suffixes: headerActions,
          );

    return FScaffold(
      header: header,
      footer: footer,
      child: body,
    );
  }
}
