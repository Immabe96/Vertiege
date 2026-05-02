import 'package:flutter/material.dart';

class AppProgressBar extends StatelessWidget {
  final int current;
  final int max;
  final String? label;
  final double height;

  const AppProgressBar({super.key, required this.current, required this.max, this.label, this.height = 8});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fraction = max > 0 ? (current / max).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label!, style: theme.textTheme.labelMedium),
              Text('$current/$max', style: theme.textTheme.labelSmall),
            ],
          ),
          const SizedBox(height: 4),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: height,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
          ),
        ),
      ],
    );
  }
}
