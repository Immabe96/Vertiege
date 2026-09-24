import 'package:flutter/material.dart';

import '../../theme/v_tokens.dart';
import '../icons/v_icons.dart';

/// A single action in [VContextMenu].
class VContextMenuAction {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool destructive;

  const VContextMenuAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.destructive = false,
  });
}

/// Unified long-press / overflow context menu (DCX-114).
class VContextMenu {
  VContextMenu._();

  static Future<void> show({
    required BuildContext context,
    required Offset globalPosition,
    required List<VContextMenuAction> actions,
  }) async {
    if (actions.isEmpty) return;

    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final relative = RelativeRect.fromRect(
      Rect.fromLTWH(globalPosition.dx, globalPosition.dy, 0, 0),
      Offset.zero & overlay.size,
    );

    await showMenu<void>(
      context: context,
      position: relative,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(VRadius.md),
      ),
      items: [
        for (final action in actions)
          PopupMenuItem<void>(
            onTap: action.onTap,
            child: Row(
              children: [
                Icon(
                  action.icon,
                  size: VIconSize.md,
                  color: action.destructive
                      ? Theme.of(context).colorScheme.error
                      : null,
                ),
                const SizedBox(width: VSpacing.sm),
                Text(
                  action.label,
                  style: TextStyle(
                    color: action.destructive
                        ? Theme.of(context).colorScheme.error
                        : null,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Wraps [child] with a long-press handler that opens [actions].
  static Widget longPress({
    required BuildContext context,
    required Widget child,
    required List<VContextMenuAction> actions,
  }) {
    return GestureDetector(
      onLongPress: () {
        final box = context.findRenderObject() as RenderBox?;
        if (box == null) return;
        final center = box.localToGlobal(box.size.center(Offset.zero));
        show(
          context: context,
          globalPosition: center,
          actions: actions,
        );
      },
      child: child,
    );
  }
}

/// Standard copy / share / report actions for message-like content.
List<VContextMenuAction> messageContextActions({
  VoidCallback? onCopy,
  VoidCallback? onShare,
  VoidCallback? onReport,
}) {
  return [
    if (onCopy != null)
      VContextMenuAction(
        label: 'Copy',
        icon: Icons.copy,
        onTap: onCopy,
      ),
    if (onShare != null)
      VContextMenuAction(
        label: 'Share',
        icon: VIcons.share,
        onTap: onShare,
      ),
    if (onReport != null)
      VContextMenuAction(
        label: 'Report',
        icon: Icons.flag_outlined,
        onTap: onReport,
        destructive: true,
      ),
  ];
}
