import 'package:flutter/material.dart';
import 'notification_bell.dart';

class ScreenHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;
  final bool showBell;
  final VoidCallback? onBellPress;

  const ScreenHeader({
    super.key,
    required this.title,
    this.onBack,
    this.showBell = false,
    this.onBellPress,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            if (onBack != null)
              IconButton(icon: const Icon(Icons.arrow_back), onPressed: onBack),
            Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
            if (showBell) NotificationBell(onPress: onBellPress),
          ],
        ),
      ),
    );
  }
}
