import 'package:flutter/material.dart';
import 'access_icon.dart';

class AccessGuard extends StatelessWidget {
  final int requiredTier;
  final int residentTier;
  final Widget child;
  final VoidCallback? onApply;

  const AccessGuard({
    super.key,
    required this.requiredTier,
    required this.residentTier,
    required this.child,
    this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    if (residentTier >= requiredTier) return child;

    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AccessIcon(type: AccessIconType.locked, size: 48),
              const SizedBox(height: 16),
              Text('Tier $requiredTier+ Required', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text('Reach tier $requiredTier to unlock this content.',
                  textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 16),
              if (onApply != null)
                FilledButton(onPressed: onApply, child: const Text('Apply for Access')),
            ],
          ),
        ),
      ),
    );
  }
}
