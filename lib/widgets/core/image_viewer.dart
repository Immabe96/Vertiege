import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../theme/design_system.dart';
import '../../theme/v_colors.dart';
import 'shimmer.dart';

class ImageViewer extends StatefulWidget {
  final String imageUrl;
  final String? heroTag;

  const ImageViewer({super.key, required this.imageUrl, this.heroTag});

  /// Opens the image viewer as a fullscreen overlay modal.
  ///
  /// [imageUrl] is required. If [heroTag] is provided, the image enters with
  /// a Hero animation — the source widget must wrap its image in a [Hero] with
  /// the same tag.
  static Future<void> show(
    BuildContext context, {
    required String imageUrl,
    String? heroTag,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierColor: VColors.scrimDark,
      barrierDismissible: true,
      barrierLabel: 'Image viewer',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, _, _) {
        return ImageViewer(imageUrl: imageUrl, heroTag: heroTag);
      },
      transitionBuilder: (context, animation, _, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  @override
  State<ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer> {
  bool _isLoading = true;
  bool _hasError = false;

  void _markLoaded() {
    if (!_isLoading) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _isLoading) {
        setState(() => _isLoading = false);
      }
    });
  }

  void _markLoading() {
    if (_isLoading) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isLoading) {
        setState(() => _isLoading = true);
      }
    });
  }

  void _markError() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    });
  }

  Widget _buildImage() {
    return Image.network(
      widget.imageUrl,
      fit: BoxFit.contain,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          _markLoaded();
          return child;
        }
        _markLoading();
        return const SizedBox.shrink();
      },
      errorBuilder: (context, error, stackTrace) {
        _markError();
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildCloseButton() {
    return ClipOval(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: VColors.onPrimary.withValues(alpha: 0.14),
            border: Border.all(
              color: VColors.onPrimary.withValues(alpha: 0.28),
              width: 0.5,
            ),
          ),
          child: const Center(
            child: Icon(Icons.close_rounded, color: VColors.onPrimary, size: 22),
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Pulse(
      width: 240,
      height: 180,
      borderRadius: RadiusTokens.card,
    );
  }

  Widget _buildError() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.broken_image_outlined,
          size: VIconSize.xl,
          color: VColors.onPrimary.withValues(alpha: 0.6),
        ),
        const SizedBox(height: VSpacing.md),
        Text(
          'Failed to load',
          style: TextStyle(
            color: VColors.onPrimary.withValues(alpha: 0.7),
            fontSize: VFontSize.bodyMd,
            fontWeight: VFontWeight.regular,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget imageWidget = _buildImage();

    final Widget heroImage;
    if (widget.heroTag != null) {
      heroImage = Hero(tag: widget.heroTag!, child: imageWidget);
    } else {
      heroImage = imageWidget;
    }

    return Material(
      color: Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Tappable background — tap anywhere on the dark backdrop to dismiss.
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).pop(),
            child: Container(color: Colors.transparent),
          ),

          // Safe-area-aware content layer.
          SafeArea(
            child: Stack(
              children: [
                // Pinch-to-zoom image.
                Center(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 5.0,
                    child: heroImage,
                  ),
                ),

                // Loading shimmer.
                if (_isLoading && !_hasError) Center(child: _buildLoading()),

                // Error state.
                if (_hasError) Center(child: _buildError()),

                // Glass-morphism close button.
                Positioned(
                  top: Spacing.md,
                  right: Spacing.md,
                  child: _buildCloseButton(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
