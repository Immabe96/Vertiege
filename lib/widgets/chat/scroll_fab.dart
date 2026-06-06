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
class ChatScrollFab extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final showBadge = badgeCount > 0;
    final label = badgeCount > 99 ? '99+' : '$badgeCount';

    if (useCommuneStyle) {
      return Material(
        elevation: 0,
        color: VCommuneColors.surfaceFloating,
        borderRadius: BorderRadius.circular(VRadius.pill),
        child: InkWell(
          onTap: onTap,
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
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      color: VCommuneColors.headerPrimary,
                      borderRadius: BorderRadius.circular(VRadius.pill),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      label,
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

    return Material(
      elevation: 4,
      shape: const CircleBorder(),
      color: VCommuneColors.surfaceFloating,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
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
