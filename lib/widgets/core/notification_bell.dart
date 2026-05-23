import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/notification_provider.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';

class NotificationBell extends ConsumerStatefulWidget {
  final double size;
  final VoidCallback? onPress;

  const NotificationBell({super.key, this.size = 22, this.onPress});

  @override
  ConsumerState<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends ConsumerState<NotificationBell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _handlePress() {
    HapticFeedback.lightImpact();
    widget.onPress?.call();
  }

  @override
  Widget build(BuildContext context) {
    final unread = ref.watch(
      notificationProvider.select(
        (s) => s.notifications.where((n) => !n.read).length,
      ),
    );

    // Start or stop the pulse animation based on unread count
    if (unread > 0 && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (unread == 0 && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.reset();
    }

    final iconData = unread > 0
        ? Icons.notifications
        : Icons.notifications_outlined;

    return Semantics(
      label: 'Notifications, $unread unread',
      button: true,
      child: IconButton(
        icon: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: unread > 0 ? _pulseAnimation.value : 1.0,
              child: child,
            );
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(iconData, size: widget.size, color: VColors.tertiary),
              if (unread > 0)
                Positioned(
                  top: -widget.size * 0.2,
                  right: -widget.size * 0.25,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: VAnimation.normal,
                    curve: VAnimation.spring,
                    key: ValueKey(unread),
                    builder: (context, scale, child) {
                      return Transform.scale(scale: scale, child: child);
                    },
                    child: _Badge(count: unread),
                  ),
                ),
            ],
          ),
        ),
        onPressed: _handlePress,
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final int count;
  const _Badge({required this.count});

  @override
  Widget build(BuildContext context) {
    final text = count > 9 ? '9+' : '$count';
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [VColors.error, VColors.tierHustler],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      child: Text(
        text,
        style: const TextStyle(
          color: VColors.onPrimary,
          fontSize: VFontSize.labelSm,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
