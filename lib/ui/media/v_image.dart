import 'package:flutter/material.dart';
import '../../theme/v_colors.dart';

/// Standard image widget with fallback chain:
/// 1. Supabase/network image
/// 2. Bundled asset
/// 3. Category placeholder (colored container with icon)
/// 4. Minimal icon empty state
class VImage extends StatelessWidget {
  final String? imageUrl;
  final String? assetPath;
  final IconData placeholderIcon;
  final Color? placeholderColor;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final bool showLoadingIndicator;

  const VImage({
    super.key,
    this.imageUrl,
    this.assetPath,
    this.placeholderIcon = Icons.image_outlined,
    this.placeholderColor,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.showLoadingIndicator = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget placeholder = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: placeholderColor?.withValues(alpha: 0.12) ??
            (isDark
                ? VColors.surfaceContainerHighestDark.withValues(alpha: 0.3)
                : VColors.surfaceContainerHighest.withValues(alpha: 0.3)),
        borderRadius: borderRadius,
      ),
      child: Icon(
        placeholderIcon,
        size: (width != null && height != null)
            ? (width! < height! ? width! * 0.4 : height! * 0.4)
            : 32,
        color: placeholderColor ??
            (isDark ? VColors.onSurfaceVariantDark : VColors.onSurfaceVariant),
      ),
    );

    Widget imageWidget;
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      imageWidget = ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: Image.network(
          imageUrl!,
          width: width,
          height: height,
          fit: fit,
          loadingBuilder: showLoadingIndicator
              ? (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return placeholder;
                }
              : null,
          errorBuilder: (context, error, stackTrace) {
            if (assetPath != null) {
              return Image.asset(
                assetPath!,
                width: width,
                height: height,
                fit: fit,
                errorBuilder: (c, e, s) => placeholder,
              );
            }
            return placeholder;
          },
        ),
      );
    } else if (assetPath != null) {
      imageWidget = ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: Image.asset(
          assetPath!,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => placeholder,
        ),
      );
    } else {
      imageWidget = placeholder;
    }

    if (borderRadius != null && imageWidget is! ClipRRect) {
      return ClipRRect(borderRadius: borderRadius!, child: imageWidget);
    }
    return imageWidget;
  }
}
