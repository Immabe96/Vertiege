import 'package:flutter/material.dart';

class ThemedText extends StatelessWidget {
  final String text;
  final ThemedTextType type;
  final Color? color;

  const ThemedText(this.text, {super.key, this.type = ThemedTextType.body, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = switch (type) {
      ThemedTextType.hero => theme.textTheme.displayLarge,
      ThemedTextType.headline => theme.textTheme.headlineMedium,
      ThemedTextType.title => theme.textTheme.titleLarge,
      ThemedTextType.subtitle => theme.textTheme.titleMedium,
      ThemedTextType.body => theme.textTheme.bodyLarge,
      ThemedTextType.bodySmall => theme.textTheme.bodyMedium,
      ThemedTextType.caption => theme.textTheme.labelSmall,
      ThemedTextType.link => theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.primary,
            decoration: TextDecoration.underline,
          ),
    };

    return Text(text, style: style?.copyWith(color: color));
  }
}

enum ThemedTextType { hero, headline, title, subtitle, body, bodySmall, caption, link }
