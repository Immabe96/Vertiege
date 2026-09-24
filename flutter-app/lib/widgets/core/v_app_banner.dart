import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../../theme/v_tokens.dart';

/// Top-of-app status strip using [FAlert] (replaces [MaterialBanner]).
class VAppBanner extends StatelessWidget {
  final String message;
  final FAlertVariant variant;
  final Widget? action;

  const VAppBanner({
    super.key,
    required this.message,
    this.variant = .primary,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          VSpacing.sm,
          VSpacing.xs,
          VSpacing.sm,
          0,
        ),
        child: FAlert(
          variant: variant,
          icon: Icon(
            variant == .destructive
                ? FIcons.circleAlert
                : FIcons.info,
          ),
          title: Text(message),
          subtitle: action,
        ),
      ),
    );
  }
}
