import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/identity_verification.dart';
import '../../theme/v_colors.dart';
import '../../models/resident.dart';
import '../../services/identity_verify_banner_prefs.dart';
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
/// Unverified residents can dismiss the full banner for this device; a compact
/// row remains so verification stays reachable.
class IdentityVerificationCard extends ConsumerStatefulWidget {
  const IdentityVerificationCard({super.key});

  @override
  ConsumerState<IdentityVerificationCard> createState() =>
      _IdentityVerificationCardState();
}

class _IdentityVerificationCardState
    extends ConsumerState<IdentityVerificationCard> {
  String? _pendingProfession;
  bool _dismissed = false;
  bool _prefsLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_loadPending());
      unawaited(_loadDismissed());
    });
  }

  Future<void> _loadDismissed() async {
    final dismissed = await IdentityVerifyBannerPrefs.isDismissed();
    if (!mounted) return;
    setState(() {
      _dismissed = dismissed;
      _prefsLoaded = true;
    });
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

  Future<void> _dismiss() async {
    setState(() => _dismissed = true);
    await IdentityVerifyBannerPrefs.dismiss();
  }

  @override
  Widget build(BuildContext context) {
    final resident = ref.watch(residentProvider).resident;
    if (resident == null) return const SizedBox.shrink();

    final brightness = Theme.of(context).brightness;
    final verified = IdentityVerification.isVerified(resident);
    final pending = _pendingProfession != null;

    if (verified) {
      return _VerifiedCompact(brightness: brightness);
    }

    if (!_prefsLoaded) return const SizedBox.shrink();

    if (_dismissed && !pending) {
      return _CompactPrompt(
        brightness: brightness,
        onVerify: () => _openSheet(resident),
      );
    }

    final statusLine = pending
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
                    VIcons.shield,
                    color: VCommuneColors.textLinkOf(brightness),
                    size: VIconSize.lg,
                  ),
                  const SizedBox(width: VSpacing.sm),
                  Expanded(
                    child: Text(
                      pending ? 'Verification pending' : 'Verify your identity',
                      style: TextStyle(
                        fontSize: VFontSize.headlineSm,
                        fontWeight: VFontWeight.bold,
                        color: VCommuneColors.headerPrimaryOf(brightness),
                      ),
                    ),
                  ),
                  if (!pending)
                    IconButton(
                      tooltip: 'Dismiss',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => unawaited(_dismiss()),
                      icon: Icon(
                        Icons.close,
                        size: 18,
                        color: VCommuneColors.textMutedOf(brightness),
                      ),
                    ),
                ],
              ),
              if (!pending) ...[
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
              ],
              const SizedBox(height: VSpacing.xs),
              Text(
                statusLine,
                style: TextStyle(
                  fontSize: VFontSize.labelSm,
                  fontWeight: VFontWeight.semiBold,
                  color: VCommuneColors.textNormalOf(brightness),
                ),
              ),
              if (!pending) ...[
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

class _VerifiedCompact extends StatelessWidget {
  final Brightness brightness;

  const _VerifiedCompact({required this.brightness});

  @override
  Widget build(BuildContext context) {
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
          padding: const EdgeInsets.symmetric(
            horizontal: VSpacing.md,
            vertical: VSpacing.sm,
          ),
          child: Row(
            children: [
              const Icon(VIcons.badgeCheck, color: VColors.brand, size: 22),
              const SizedBox(width: VSpacing.sm),
              Expanded(
                child: Text(
                  'Verified resident',
                  style: TextStyle(
                    fontSize: VFontSize.bodyMd,
                    fontWeight: VFontWeight.semiBold,
                    color: VCommuneColors.headerPrimaryOf(brightness),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactPrompt extends StatelessWidget {
  final Brightness brightness;
  final VoidCallback onVerify;

  const _CompactPrompt({
    required this.brightness,
    required this.onVerify,
  });

  @override
  Widget build(BuildContext context) {
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
        child: InkWell(
          onTap: onVerify,
          borderRadius: BorderRadius.circular(VRadius.lg),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: VSpacing.md,
              vertical: VSpacing.sm,
            ),
            child: Row(
              children: [
                Icon(
                  VIcons.shield,
                  color: VCommuneColors.textLinkOf(brightness),
                  size: VIconSize.md,
                ),
                const SizedBox(width: VSpacing.sm),
                Expanded(
                  child: Text(
                    'Verify identity for your tick',
                    style: TextStyle(
                      fontSize: VFontSize.bodyMd,
                      fontWeight: VFontWeight.semiBold,
                      color: VCommuneColors.headerPrimaryOf(brightness),
                    ),
                  ),
                ),
                Icon(
                  VIcons.chevronRight,
                  size: 18,
                  color: VCommuneColors.textMutedOf(brightness),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
