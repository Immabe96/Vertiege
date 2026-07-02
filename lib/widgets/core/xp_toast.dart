
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';

class XpToast {
  static void show(BuildContext context, {required int amount}) {
    HapticFeedback.lightImpact();

    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) =>
          _XpToastWidget(amount: amount, onDismiss: () => entry.remove()),
    );

    overlay.insert(entry);
  }
}

class _XpToastWidget extends StatefulWidget {
  final int amount;
  final VoidCallback onDismiss;

  const _XpToastWidget({required this.amount, required this.onDismiss});

  @override
  State<_XpToastWidget> createState() => _XpToastWidgetState();
}

class _XpToastWidgetState extends State<_XpToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _slide;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: VAnimation.entrance,
      vsync: this,
    );

    _slide = Tween<double>(
      begin: -60,
      end: 0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
    _scale = Tween<double>(
      begin: 0.8,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _controller.reverse().then((_) => widget.onDismiss());
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + VSpacing.md,
      right: VSpacing.md,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Opacity(
            opacity: _fade.value,
            child: Transform.translate(
              offset: Offset(0, _slide.value),
              child: Transform.scale(scale: _scale.value, child: child),
            ),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(VRadius.pill),
          child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: VSpacing.md,
                vertical: VSpacing.sm + 2,
              ),
              decoration: BoxDecoration(
                color: VColors.surfaceContainerDark,
                borderRadius: BorderRadius.circular(VRadius.pill),
                border: Border.all(color: VColors.outlineVariantDark),
                boxShadow: [
                  // Outer glow in gold
                  BoxShadow(
                    color: VColors.tertiary.withValues(
                      alpha: 0.45,
                    ),
                    blurRadius: 18,
                    offset: const Offset(0, 4),
                  ),
                  // Inner glow ring
                  BoxShadow(
                    color: VColors.primary.withValues(
                      alpha: 0.3,
                    ),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.bolt,
                    color: VColors.tertiary,
                    size: VIconSize.md,
                  ),
                  const SizedBox(width: VSpacing.xs),
                  Text(
                    '+${widget.amount} XP',
                    style: const TextStyle(
                      color: VColors.tertiary,
                      fontSize: VFontSize.bodyMd,
                      fontWeight: VFontWeight.bold,
                    ),
                  ),
                ],
              ),
          ),
        ),
      ),
    );
  }
}
