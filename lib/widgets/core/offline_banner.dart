import 'package:flutter/material.dart';

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
          MaterialBanner(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            content: const Text('Connection issue. Pull to retry.',
                style: TextStyle(fontSize: 13)),
            leading: Icon(Icons.cloud_off, size: 20,
                color: Theme.of(context).colorScheme.error),
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
            actions: [
              if (onRetry != null)
                TextButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        Expanded(child: child),
      ],
    );
  }
}
