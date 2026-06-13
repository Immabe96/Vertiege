import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../../utils/v_motion.dart';

/// Variant determines the color tint applied to the empty state.
enum EmptyStateVariant { default_, error, success }

/// Commune illustration presets for empty states (DCX-116).
enum EmptyStateIllustration {
  default_,
  worlds,
  chat,
  achievements,
  nexus,
}

/// Compact Forui-aligned empty state: muted icon, title, optional CTA.
class AppEmptyState extends ConsumerStatefulWidget {
  final String title;
  final String? description;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EmptyStateVariant variant;
  final EmptyStateIllustration illustration;

  const AppEmptyState({
    super.key,
    required this.title,
    this.description,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
    this.variant = EmptyStateVariant.default_,
    this.illustration = EmptyStateIllustration.default_,
  });

  @override
  ConsumerState<AppEmptyState> createState() => _AppEmptyStateState();
}

class _AppEmptyStateState extends ConsumerState<AppEmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;

  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: VAnimation.fast,
      vsync: this,
    );
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: VAnimation.standard),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!context.motionEnabled) {
      _controller.value = 1.0;
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _variantColor(BuildContext context) {
    switch (widget.variant) {
      case EmptyStateVariant.error:
        return VColors.error;
      case EmptyStateVariant.success:
        return VColors.success;
      case EmptyStateVariant.default_:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }

  IconData _illustrationIcon() {
    if (widget.illustration != EmptyStateIllustration.default_) {
      return switch (widget.illustration) {
        EmptyStateIllustration.worlds => Icons.public,
        EmptyStateIllustration.chat => Icons.forum_outlined,
        EmptyStateIllustration.achievements => Icons.emoji_events_outlined,
        EmptyStateIllustration.nexus => Icons.dynamic_feed_outlined,
        EmptyStateIllustration.default_ => widget.icon,
      };
    }
    return widget.icon;
  }

  List<Color> _illustrationGradient(Color base) {
    return [
      base.withValues(alpha: 0.18),
      base.withValues(alpha: 0.06),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final variantColor = _variantColor(context);

    return FadeTransition(
      opacity: _fade,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 48,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _illustrationGradient(variantColor),
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: variantColor.withValues(alpha: 0.12),
                  ),
                ),
                child: Icon(
                  _illustrationIcon(),
                  size: VIconSize.xl,
                  color: variantColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              if (widget.description != null) ...[
                const SizedBox(height: 4),
                Text(
                  widget.description!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (widget.actionLabel != null && widget.onAction != null) ...[
                const SizedBox(height: 16),
                FButton(
                  onPress: widget.onAction,
                  child: Text(widget.actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Convenience widget wrapping [AppEmptyState] for error states.
class AppErrorState extends StatelessWidget {
  final String? message;
  final VoidCallback? onRetry;

  const AppErrorState({super.key, this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      title: 'Something went wrong',
      description: message ?? 'An unexpected error occurred. Please try again.',
      icon: Icons.error_outline,
      actionLabel: 'Retry',
      onAction: onRetry,
      variant: EmptyStateVariant.error,
    );
  }
}
