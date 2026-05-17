import 'package:flutter/material.dart';
import '../../theme/design_system.dart';

class CompletionHint extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  const CompletionHint({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.onTap,
  });

  @override
  State<CompletionHint> createState() => _CompletionHintState();
}

class _CompletionHintState extends State<CompletionHint> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.xs + 2,
      ),
      child: Dismissible(
        key: ValueKey('hint-${widget.title}'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: Spacing.md),
          child: Icon(Icons.close, color: theme.colorScheme.outline),
        ),
        onDismissed: (_) => setState(() => _dismissed = true),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(RadiusTokens.card),
            child: Container(
              padding: const EdgeInsets.all(Spacing.md - 4),
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(RadiusTokens.card),
                border: Border.all(color: widget.color.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(RadiusTokens.input),
                    ),
                    child: Icon(
                      widget.icon,
                      size: IconSizes.md,
                      color: widget.color,
                    ),
                  ),
                  const SizedBox(width: Spacing.md - 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeights.bold,
                          ),
                        ),
                        Text(
                          widget.subtitle,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: IconSizes.xs + 2,
                    color: theme.colorScheme.outline,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
