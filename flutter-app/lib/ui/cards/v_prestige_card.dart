import 'package:flutter/material.dart';

import '../../theme/prestige_noir.dart';
import '../../theme/v_tokens.dart';

/// Raised Prestige Noir panel — matches Open Design bento / section cards.
///
/// This is the single raised-card primitive — it also replaces the former
/// `PrestigeRaisedCard` and `SovereignCard`.
class VPrestigeCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool raised;
  final Color? backgroundColor;
  final Color? borderColor;
  final Gradient? backgroundGradient;

  const VPrestigeCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(VSpacing.md),
    this.onTap,
    this.raised = true,
    this.backgroundColor,
    this.borderColor,
    this.backgroundGradient,
  });

  @override
  Widget build(BuildContext context) {
    final surface = backgroundColor ??
        (raised ? PrestigeNoir.surfaceRaised : PrestigeNoir.surface);
    final content = Container(
      decoration: BoxDecoration(
        color: backgroundGradient == null ? surface : null,
        gradient: backgroundGradient,
        borderRadius: BorderRadius.circular(VRadius.bento),
        border: Border.all(color: borderColor ?? PrestigeNoir.borderLight),
      ),
      padding: padding,
      child: child,
    );
    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(VRadius.bento),
        child: content,
      ),
    );
  }
}

/// Uppercase muted section label (prototype `.sec-header` / `.card-label`).
class VPrestigeSectionLabel extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const VPrestigeSectionLabel({
    super.key,
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: VSpacing.sm),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: VFontSize.labelSm,
              fontWeight: VFontWeight.semiBold,
              letterSpacing: 0.6,
              color: PrestigeNoir.mutedDim,
            ),
          ),
          if (trailing != null) ...[
            const Spacer(),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/// Gold progress track — readable empty fill on Prestige Noir surfaces.
class VPrestigeProgressBar extends StatelessWidget {
  final double value;
  final double height;
  final Color? color;

  const VPrestigeProgressBar({
    super.key,
    required this.value,
    this.height = 8,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: height,
        backgroundColor: PrestigeNoir.borderLight,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? PrestigeNoir.accent,
        ),
      ),
    );
  }
}
