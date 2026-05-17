import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

/// Wraps [child] in a [RepaintBoundary] and captures it as a PNG when tapped.
///
/// Usage:
/// ```dart
/// ShareButton(
///   shareText: 'Join me on Vertiege!',
///   child: WorldShareCard(world: myWorld),
/// )
/// ```
///
/// On tap the widget:
/// 1. Captures the child widget as a high-resolution PNG (3x pixel ratio)
/// 2. Writes the image to a temporary file
/// 3. Opens the platform share sheet via [Share.shareXFiles]
/// 4. Shows a loading indicator while capturing
class ShareButton extends StatefulWidget {
  /// The widget to capture and share as an image.
  final Widget child;

  /// Text to include alongside the shared image (optional).
  final String? shareText;

  /// Called after the share sheet is dismissed.
  final VoidCallback? onShared;

  const ShareButton({
    super.key,
    required this.child,
    this.shareText,
    this.onShared,
  });

  @override
  State<ShareButton> createState() => _ShareButtonState();
}

class _ShareButtonState extends State<ShareButton> {
  final _key = GlobalKey();
  bool _isCapturing = false;

  Future<void> _captureAndShare() async {
    if (_isCapturing) return;

    setState(() => _isCapturing = true);

    try {
      final boundary =
          _key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final pngBytes = byteData.buffer.asUint8List();
      final tempFile = await _writeTempFile(pngBytes);
      if (tempFile != null) {
        await Share.shareXFiles([
          XFile(tempFile),
        ], text: widget.shareText ?? 'Join me on Vertiege!');
        widget.onShared?.call();
      }
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  Future<String?> _writeTempFile(Uint8List bytes) async {
    try {
      final dir = Directory.systemTemp;
      final file = File(
        '${dir.path}/vertiege_share_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(bytes);
      return file.path;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isCapturing ? null : _captureAndShare,
      child: RepaintBoundary(
        key: _key,
        child: Stack(
          children: [
            widget.child,
            if (_isCapturing)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0x99000000),
                    borderRadius: BorderRadius.circular(
                      28,
                    ), // matches card radius
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
