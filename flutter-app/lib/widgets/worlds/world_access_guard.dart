import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/world.dart';
import '../../models/resident.dart';
import '../../state/resident_provider.dart';
import '../../state/world_provider.dart';
import '../../services/access_control.dart';
import '../../theme/v_tokens.dart';
import '../../widgets/core/loading_state.dart';
import 'access_icon.dart';
import '../../ui/buttons/v_button.dart';
import '../../ui/icons/v_icons.dart';
import '../../ui/overlays/v_sheet.dart';
import '../../widgets/core/v_feedback.dart';

class WorldAccessGuard extends ConsumerWidget {
  final String worldId;
  final Widget child;

  const WorldAccessGuard({
    super.key,
    required this.worldId,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final world = ref.watch(worldProvider).worlds[worldId];
    final resident = ref.watch(residentProvider).resident;
    final verificationStatus = ref.watch(residentProvider).verificationStatus;
    final theme = Theme.of(context);

    if (world == null) {
      return Center(
        child: Text('World not found', style: theme.textTheme.bodyLarge),
      );
    }

    if (resident == null) {
      return Center(
        child: VButton(
          label: 'Get Started',
          onPressed: () => context.go('/onboarding'),
        ),
      );
    }

    if (canAccessWorld(resident, world)) return child;

    final isVerifying = verificationStatus == VerificationStatus.verifying;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(VRadius.md),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AccessIcon(size: 48),
              const SizedBox(height: 16),
              Text('Access Restricted', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                world.description,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              if (isVerifying)
                const Column(
                  children: [
                    VLoadingCard(),
                    SizedBox(height: 12),
                    Text('Submitting verification...'),
                  ],
                )
              else
                VButton(
                  label: world.type == WorldType.wealth
                      ? 'Unlock Access'
                      : 'Verify Profession',
                  onPressed: () => _handleAccess(context, ref, world, resident),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleAccess(
    BuildContext context,
    WidgetRef ref,
    World world,
    Resident resident,
  ) {
    if (world.type == WorldType.wealth) {
      _showTierRequirementSheet(context, world);
    } else if (world.type == WorldType.profession) {
      _showVerificationSheet(context, ref, world.requiredProfession ?? '');
    }
  }

  void _showTierRequirementSheet(BuildContext context, World world) {
    final tier = world.requiredTier ?? 1;
    final title = switch (tier) {
      2 => 'High Roller',
      3 => 'Elite',
      4 => 'Old Money',
      5 => 'Apex',
      _ => 'Resident',
    };

    showVSheet(
      context,
      Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Unlock ${world.name}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              world.description,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Text(
              '$title tier required',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'World access is earned through real-life achievements and verified XP.',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: 16),
            VButton(
              label: 'Go to Achievements',
              icon: const Icon(VIcons.trophy),
              isFullWidth: true,
              onPressed: () {
                Navigator.pop(context);
                context.push('/achievements');
              },
            ),
            const SizedBox(height: 8),
            VButton(
              label: 'Close',
              onPressed: () {
                Navigator.pop(context);
              },
              variant: ButtonVariant.text,
              isFullWidth: true,
            ),
          ],
        ),
      ),
      maxSize: 0.55,
    );
  }

  void _showVerificationSheet(
    BuildContext context,
    WidgetRef ref,
    String profession,
  ) {
    showVSheet(
      context,
      _VerificationSheet(
        profession: profession,
        onSubmit: (proofPath) {
          Navigator.pop(context);
          ref
              .read(residentProvider.notifier)
              .verifyProfession(profession, proofPath: proofPath);
          VFeedback.showMessage(context, 'Verification submitted. You will be notified when it is reviewed.',);
        },
      ),
      maxSize: 0.75,
    );
  }
}

class _VerificationSheet extends StatefulWidget {
  final String profession;
  final void Function(String proofPath) onSubmit;

  const _VerificationSheet({required this.profession, required this.onSubmit});

  @override
  State<_VerificationSheet> createState() => _VerificationSheetState();
}

class _VerificationSheetState extends State<_VerificationSheet> {
  String? _proofPath;
  final _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Verify ${widget.profession}',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Upload proof of your profession (job letter, certificate, or qualification document).'
            ' Verification is manual and may take some time.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 16),
          if (_proofPath != null)
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(VRadius.lg),
                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(VRadius.lg),
                child: Image.file(File(_proofPath!), fit: BoxFit.cover),
              ),
            )
          else
            VButton(
              label: 'Upload proof document',
              onPressed: _pickProof,
              icon: const Icon(VIcons.upload),
              variant: ButtonVariant.outlined,
            ),
          const SizedBox(height: 16),
          VButton(
            label: 'Submit for Review',
            onPressed: _proofPath != null
                ? () => widget.onSubmit(_proofPath!)
                : null,
            isFullWidth: true,
          ),
        ],
      ),
    );
  }

  Future<void> _pickProof() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file != null && mounted) {
      setState(() => _proofPath = file.path);
    }
  }
}
