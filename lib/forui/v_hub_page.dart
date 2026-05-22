import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

/// Hub-style sub-page: [FScaffold] + [FHeader] (Forui / shadcn layout).
class VHubPage extends StatelessWidget {
  final String title;
  final Widget body;
  final bool showBack;
  final List<Widget> headerActions;
  final Widget? footer;

  const VHubPage({
    super.key,
    required this.title,
    required this.body,
    this.showBack = false,
    this.headerActions = const [],
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final header = showBack
        ? FHeader.nested(
            title: Text(title),
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
            title: Text(title),
            suffixes: headerActions,
          );

    return FScaffold(
      header: header,
      footer: footer,
      child: body,
    );
  }
}
