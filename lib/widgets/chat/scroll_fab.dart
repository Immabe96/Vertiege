import 'package:flutter/material.dart';

import '../../theme/v_commune_colors.dart';
import '../../theme/v_tokens.dart';

/// Tracks jump-to-present visibility and new messages while scrolled away.
class ChatScrollFabTracker {
  bool show = false;
  int badgeCount = 0;
  int _anchorMessageCount = 0;
  int _lastMessageCount = 0;

  /// Returns true when [show] or [badgeCount] changed (caller should setState).
  bool syncMessageCount(int count) {
    _lastMessageCount = count;
    if (!show) {
      _anchorMessageCount = count;
      if (badgeCount != 0) {
        badgeCount = 0;
        return true;
      }
      return false;
    }
    final next = (count - _anchorMessageCount).clamp(0, 99);
    if (next == badgeCount) return false;
    badgeCount = next;
    return true;
  }

  /// Returns true when [show] changed (caller should setState).
  bool updateFromScroll(ScrollController controller, {double threshold = 200}) {
    if (!controller.hasClients) return false;
    final offset = controller.offset;
    final maxExtent = controller.position.maxScrollExtent;
    final away = (maxExtent - offset) > threshold;
    if (!away) {
      if (!show && badgeCount == 0) return false;
      show = false;
      badgeCount = 0;
      _anchorMessageCount = _lastMessageCount;
      return true;
    }
    if (!show) {
      show = true;
      _anchorMessageCount = _lastMessageCount;
      badgeCount = 0;
      return true;
    }
    return false;
  }
}

/// Jump-to-present control — commune surface, optional new-message badge (DCX-055).
class ChatScrollFab extends StatefulWidget {
  final VoidCallback onTap;
  final int badgeCount;
  final bool useCommuneStyle;

  const ChatScrollFab({
    super.key,
    required this.onTap,
    this.badgeCount = 0,
    this.useCommuneStyle = true,
  });

  @override
  State<ChatScrollFab> createState() => _ChatScrollFabState();
}

class _ChatScrollFabState extends State<ChatScrollFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  late final Animation<double> _scaleIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scaleIn = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.value = 1.0;
  }

  @override
  void didUpdateWidget(ChatScrollFab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.badgeCount > 0 && oldWidget.badgeCount == 0) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showBadge = widget.badgeCount > 0;
    final countLabel = widget.badgeCount > 99 ? '99+' : '${widget.badgeCount}';
    final badgeLabel = widget.badgeCount == 1 ? 'New' : 'New · $countLabel';

    return FadeTransition(
      opacity: _fadeIn,
      child: ScaleTransition(
        scale: _scaleIn,
        child: widget.useCommuneStyle
            ? _buildCommuneStyle(showBadge, badgeLabel)
            : _buildLegacyStyle(),
      ),
    );
  }

  Widget _buildCommuneStyle(bool showBadge, String badgeLabel) {
    return Material(
      elevation: 0,
      color: VCommuneColors.surfaceFloating,
      borderRadius: BorderRadius.circular(VRadius.pill),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(VRadius.pill),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: showBadge ? VSpacing.sm : VSpacing.xs,
            vertical: VSpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.keyboard_arrow_down,
                size: VIconSize.md,
                color: VCommuneColors.textNormal,
              ),
              if (showBadge) ...[
                const SizedBox(width: VSpacing.xs),
                Container(
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 24),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: VCommuneColors.headerPrimary,
                    borderRadius: BorderRadius.circular(VRadius.pill),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    badgeLabel,
                    style: const TextStyle(
                      color: VCommuneColors.surfaceFloating,
                      fontSize: VFontSize.labelSm,
                      fontWeight: VFontWeight.bold,
                      height: VLineHeight.label,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegacyStyle() {
    return Material(
      elevation: 4,
      shape: const CircleBorder(),
      color: VCommuneColors.surfaceFloating,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.all(VSpacing.sm),
          child: Icon(
            Icons.keyboard_arrow_down,
            size: VIconSize.lg,
            color: VCommuneColors.textNormal,
          ),
        ),
      ),
    );
  }
}
