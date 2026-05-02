import 'package:flutter/material.dart';
import '../../config/cosmetics.dart';

class CosmeticAvatar extends StatelessWidget {
  final int totalXp;
  final double size;
  final String? imageUrl;

  const CosmeticAvatar({super.key, this.totalXp = 0, this.size = 80, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final frame = getFrameForXp(totalXp);
    final theme = Theme.of(context);

    return Container(
      width: size + 8,
      height: size + 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: frame.color.withValues(alpha: 0.5),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: frame.color.withValues(alpha: frame.shadowOpacity),
            blurRadius: frame.shadowRadius,
            spreadRadius: 1,
          ),
        ],
      ),
      child: CircleAvatar(
        radius: size / 2,
        backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
        child: imageUrl == null ? Icon(Icons.person, size: size * 0.6) : null,
      ),
    );
  }
}
