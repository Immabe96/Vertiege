import 'package:flutter/material.dart';
import '../../theme/v_tokens.dart';
import '../../ui/icons/v_icons.dart';

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
        horizontal: VSpacing.md,
        vertical: VSpacing.xs + 2,
      ),
      child: Dismissible(
        key: ValueKey('hint-${widget.title}'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: VSpacing.md),
          child: Icon(VIcons.x, color: theme.colorScheme.outline),
        ),
        onDismissed: (_) => setState(() => _dismissed = true),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(VRadius.lg),
            child: Container(
              padding: const EdgeInsets.all(VSpacing.md - 4),
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(VRadius.lg),
                border: Border.all(color: widget.color.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(VRadius.md),
                    ),
                    child: Icon(
                      widget.icon,
                      size: VIconSize.md,
                      color: widget.color,
                    ),
                  ),
                  const SizedBox(width: VSpacing.md - 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: VFontWeight.bold,
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
                    size: VIconSize.xs + 2,
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
