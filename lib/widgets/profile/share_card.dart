import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/resident.dart';
import '../../theme/v_colors.dart';
import '../../theme/design_system.dart';
import 'cosmetic_avatar.dart';
import 'name_banner.dart';

class ShareCard extends StatefulWidget {
  final Resident resident;
  final int totalXp;
  final int achievementCount;

  const ShareCard({
    super.key,
    required this.resident,
    required this.totalXp,
    required this.achievementCount,
  });

  @override
  State<ShareCard> createState() => _ShareCardState();
}

class _ShareCardState extends State<ShareCard> {
  final _key = GlobalKey();

  Future<void> _share() async {
    final boundary =
        _key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;

    final image = await boundary.toImage(pixelRatio: 3);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return;

    final pngBytes = byteData.buffer.asUint8List();
    final tempFile = await _writeTempFile(pngBytes);
    if (tempFile != null) {
      await Share.shareXFiles([XFile(tempFile)], text: 'Check out my profile!');
    }
  }

  Future<String?> _writeTempFile(Uint8List bytes) async {
    final dir = Directory.systemTemp;
    final file = File(
      '${dir.path}/vertiege_share_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(bytes);
    return file.path;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: _share,
      child: RepaintBoundary(
        key: _key,
        child: Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.all(Spacing.lg),
          decoration: BoxDecoration(
            color: VColors.glassBackground,
            borderRadius: BorderRadius.circular(VRadius.xxxl),
            border: Border.all(color: VColors.glassBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CosmeticAvatar(totalXp: widget.totalXp, size: 60),
              const SizedBox(height: Spacing.md),
              NameBanner(
                profession: widget.resident.profession,
                name: widget.resident.name,
              ),
              const SizedBox(height: Spacing.xs),
              Text(
                widget.resident.tier.label,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: Spacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Stat(label: 'XP', value: '${widget.totalXp}'),
                  const SizedBox(width: Spacing.xl),
                  _Stat(
                    label: 'Achievements',
                    value: '${widget.achievementCount}',
                  ),
                ],
              ),
              const SizedBox(height: Spacing.sm),
              Text('Tap to share', style: theme.textTheme.labelSmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.titleMedium),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}
