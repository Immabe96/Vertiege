import 'package:flutter/material.dart';
import 'error_banner.dart';

class OfflineBanner extends StatelessWidget {
  final bool show;
  final VoidCallback? onRetry;
  final Widget child;

  const OfflineBanner({
    super.key,
    this.show = false,
    this.onRetry,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (show)
          SovereignErrorBanner(
            message: onRetry != null
                ? 'Connection issue. Tap to retry.'
                : 'Connection issue. Check your network.',
            onRetry: onRetry,
          ),
        Expanded(child: child),
      ],
    );
  }
}
