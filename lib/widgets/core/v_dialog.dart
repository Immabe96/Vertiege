import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../../theme/v_tokens.dart';

/// Forui dialog shell matching Vertiege patterns (see [DevicePermissionService]).
Future<T?> showVDialog<T>({
  required BuildContext context,
  required String title,
  required Widget content,
  List<Widget>? actions,
  TextStyle? titleStyle,
  bool scrollContent = false,
  double? maxContentHeight,
}) {
  return showFDialog<T>(
    context: context,
    builder: (dialogCtx, style, animation) => FDialog.raw(
      builder: (context, dialogStyle) {
        Widget body = content;
        if (scrollContent) {
          body = ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: maxContentHeight ?? 360,
            ),
            child: SingleChildScrollView(child: content),
          );
        }
        return Padding(
          padding: const EdgeInsets.all(VSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: titleStyle ??
                    Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: VFontWeight.bold,
                        ),
              ),
              const SizedBox(height: VSpacing.sm),
              body,
              if (actions != null && actions.isNotEmpty) ...[
                const SizedBox(height: VSpacing.lg),
                ...actions,
              ],
            ],
          ),
        );
      },
    ),
  );
}

/// Horizontal action row for [showVDialog].
Widget vDialogActionsRow(List<Widget> children) {
  return Wrap(
    alignment: WrapAlignment.end,
    spacing: VSpacing.sm,
    runSpacing: VSpacing.xs,
    children: children,
  );
}
