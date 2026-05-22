import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/design_system.dart';
import '../../../theme/v_colors.dart';
import '../../../models/resident.dart';
import '../../../services/spotlight_service.dart';
import '../../../widgets/profile/cosmetic_avatar.dart';
import '../../../ui/icons/v_icons.dart';

class SpotlightCard extends StatefulWidget {
  const SpotlightCard({super.key});

  @override
  State<SpotlightCard> createState() => _SpotlightCardState();
}

class _SpotlightCardState extends State<SpotlightCard> {
  Resident? _spotlightResident;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSpotlight();
  }

  Future<void> _loadSpotlight() async {
    try {
      final resident = await SpotlightService.getSpotlightResident('nexus');
      if (mounted) {
        setState(() {
          _spotlightResident = resident;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(VIcons.sparkles, color: VColors.tertiary, size: 16),
            const SizedBox(width: Spacing.xs),
            Text(
              'Resident Spotlight',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeights.bold,
                color: isDark ? VColors.onSurfaceDark : VColors.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.sm),
        if (_isLoading)
          const SizedBox(
            height: 60,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else if (_spotlightResident == null)
          Container(
            padding: const EdgeInsets.all(Spacing.sm),
            decoration: BoxDecoration(
              color: isDark
                  ? VColors.surfaceContainerHighDark
                  : VColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(RadiusTokens.md),
            ),
            child: Text(
              'No resident to spotlight today.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? VColors.onSurfaceVariantDark
                    : VColors.onSurfaceVariant,
              ),
            ),
          )
        else
          GestureDetector(
            onTap: () {
              context.push('/residents/${_spotlightResident!.id}');
            },
            child: Container(
              padding: const EdgeInsets.all(Spacing.sm),
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.6),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(RadiusTokens.md),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Row(
                children: [
                  CosmeticAvatar(
                    imageUrl: _spotlightResident!.avatarUrl,
                    seed: _spotlightResident!.id,
                    size: 40,
                    frameId: _spotlightResident!.avatarFrameId,
                  ),
                  const SizedBox(width: Spacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _spotlightResident!.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeights.bold,
                            color: isDark
                                ? VColors.onSurfaceDark
                                : VColors.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_spotlightResident!.profession != null)
                          Text(
                            _spotlightResident!.profession!,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: isDark
                                  ? VColors.onSurfaceVariantDark
                                  : VColors.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
