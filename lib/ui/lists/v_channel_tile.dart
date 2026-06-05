import 'package:flutter/material.dart';

import '../../theme/v_commune_colors.dart';
import '../../theme/v_tokens.dart';

/// Dense channel list row for Commune shells (icon, name, unread, mute).
class VChannelTile extends StatelessWidget {
  final IconData icon;
  final String name;
  final int unreadCount;
  final bool isMuted;
  final bool isSelected;
  final VoidCallback? onTap;

  const VChannelTile({
    super.key,
    required this.icon,
    required this.name,
    this.unreadCount = 0,
    this.isMuted = false,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasUnread = unreadCount > 0;
    final nameColor = hasUnread
        ? VCommuneColors.headerPrimary
        : VCommuneColors.textMuted;
    final iconColor = hasUnread
        ? VCommuneColors.textNormal
        : VCommuneColors.textMuted;

    return Material(
      color: isSelected
          ? VCommuneColors.modifierSelected
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: VCommuneColors.modifierHover,
        splashColor: VCommuneColors.modifierActive,
        highlightColor: VCommuneColors.modifierActive,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: VSpacing.sm,
            vertical: VSpacing.xs + 2,
          ),
          child: Row(
            children: [
              Icon(icon, size: VIconSize.md, color: iconColor),
              const SizedBox(width: VSpacing.sm),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: VFontSize.bodyMd,
                    fontWeight: hasUnread
                        ? VFontWeight.semiBold
                        : VFontWeight.medium,
                    color: nameColor,
                    height: VLineHeight.label,
                  ),
                ),
              ),
              if (isMuted)
                const Padding(
                  padding: EdgeInsets.only(left: VSpacing.xs),
                  child: Icon(
                    Icons.notifications_off_outlined,
                    size: VIconSize.sm,
                    color: VCommuneColors.textMuted,
                  ),
                ),
              if (hasUnread) ...[
                const SizedBox(width: VSpacing.xs),
                _UnreadBadge(count: unreadCount),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  final int count;

  const _UnreadBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final label = count > 99 ? '99+' : '$count';
    return Container(
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
    );
  }
}
