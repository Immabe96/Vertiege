import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/identity_verification.dart';
import '../../theme/v_colors.dart';
import '../../models/resident.dart';
import '../../services/verification_service.dart';
import '../../state/resident_provider.dart';
import '../../theme/v_commune_colors.dart';
import '../../theme/v_tokens.dart';
import '../../ui/buttons/v_button.dart';
import '../../ui/icons/v_icons.dart';
import 'identity_verification_sheet.dart';

/// Government ID verification (passport / national ID) — earns the verified tick.
///
/// Separate from **achievement proof** (`/achievements/submit`).
class IdentityVerificationCard extends ConsumerStatefulWidget {
  const IdentityVerificationCard({super.key});

  @override
  ConsumerState<IdentityVerificationCard> createState() =>
      _IdentityVerificationCardState();
}

class _IdentityVerificationCardState
    extends ConsumerState<IdentityVerificationCard> {
  String? _pendingProfession;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPending());
  }

  Future<void> _loadPending() async {
    final resident = ref.read(residentProvider).resident;
    if (resident == null) return;
    for (final key in IdentityVerification.professionKeys) {
      final status = await VerificationService.getVerificationStatus(
        resident.id,
        key,
      );
      if (status == 'pending' && mounted) {
        setState(() => _pendingProfession = key);
        return;
      }
    }
    if (mounted) setState(() => _pendingProfession = null);
  }

  void _openSheet(Resident resident) {
    showIdentityVerificationSheet(
      context,
      onSubmitted: () {
        _loadPending();
        ref.read(residentProvider.notifier).loadResident();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final resident = ref.watch(residentProvider).resident;
    if (resident == null) return const SizedBox.shrink();

    final brightness = Theme.of(context).brightness;
    final verified = IdentityVerification.isVerified(resident);
    final pending = _pendingProfession != null;

    final statusLine = verified
        ? 'Verified resident — your tick is active across Vertiege.'
        : pending
        ? '${IdentityVerification.labelForProfession(_pendingProfession!)} under review.'
        : 'Upload a passport or national ID card. Staff review grants your tick.';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        VSpacing.md,
        VSpacing.md,
        VSpacing.md,
        0,
      ),
      child: Material(
        color: VCommuneColors.surfaceSecondaryOf(brightness),
        borderRadius: BorderRadius.circular(VRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(VSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    verified ? VIcons.badgeCheck : VIcons.shield,
                    color: verified
                        ? VColors.brand
                        : VCommuneColors.textLinkOf(brightness),
                    size: VIconSize.lg,
                  ),
                  const SizedBox(width: VSpacing.sm),
                  Expanded(
                    child: Text(
                      verified ? 'Verified resident' : 'Verify your identity',
                      style: TextStyle(
                        fontSize: VFontSize.headlineSm,
                        fontWeight: VFontWeight.bold,
                        color: VCommuneColors.headerPrimaryOf(brightness),
                      ),
                    ),
                  ),
                  if (verified)
                    const Icon(VIcons.badgeCheck, color: VColors.brand, size: 22),
                ],
              ),
              const SizedBox(height: VSpacing.xs),
              Text(
                'This is not achievement proof. Government ID unlocks your '
                'verified tick — achievements are submitted separately.',
                style: TextStyle(
                  fontSize: VFontSize.bodySm,
                  height: VLineHeight.body,
                  color: VCommuneColors.textMutedOf(brightness),
                ),
              ),
              const SizedBox(height: VSpacing.xs),
              Text(
                statusLine,
                style: TextStyle(
                  fontSize: VFontSize.labelSm,
                  fontWeight: VFontWeight.semiBold,
                  color: VCommuneColors.textNormalOf(brightness),
                ),
              ),
              if (!verified && !pending) ...[
                const SizedBox(height: VSpacing.md),
                VButton(
                  label: 'Verify with passport or ID',
                  icon: const Icon(VIcons.upload, size: VIconSize.sm),
                  isFullWidth: true,
                  onPressed: () => _openSheet(resident),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
