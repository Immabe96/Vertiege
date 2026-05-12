import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/achievement.dart';
import '../../config/achievements.dart';
import '../../state/achievement_provider.dart';
import '../../services/supabase.dart';

class SubmitAchievementScreen extends ConsumerStatefulWidget {
  const SubmitAchievementScreen({super.key});

  @override
  ConsumerState<SubmitAchievementScreen> createState() => _SubmitAchievementScreenState();
}

class _SubmitAchievementScreenState extends ConsumerState<SubmitAchievementScreen> {
  String? _selectedId;
  String? _proofImagePath;
  bool _isUploading = false;

  Future<void> _pickProofImage() async {
    final picker = ImagePicker();
    final result = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1200);
    if (!mounted) return;
    if (result != null) {
      setState(() => _proofImagePath = result.path);
    }
  }

  Future<void> _submit() async {
    if (_selectedId == null) return;

    setState(() => _isUploading = true);

    String? proofUrl;
    if (_proofImagePath != null) {
      proofUrl = await _uploadToSupabase(_proofImagePath!);
      if (!mounted) return;
    }

    ref.read(achievementProvider.notifier).submitAchievement(
          _selectedId!,
          proofUrl ?? 'manual',
        );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Achievement submitted for verification')),
      );
    }
  }

  Future<String?> _uploadToSupabase(String filePath) async {
    if (!isSupabaseConfigured()) return null;
    final client = getSupabase();
    final ext = filePath.split('.').last;
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$ext';

    try {
      await client.storage.from('achievement-proofs').upload(
            fileName,
            File(filePath),
          );
      return client.storage.from('achievement-proofs').getPublicUrl(fileName);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Submit Achievement')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Select an achievement to submit for verification:',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 12),
          RadioGroup<String>(
            groupValue: _selectedId,
            onChanged: (v) => setState(() => _selectedId = v),
            child: Column(
              children: achievements.map((a) {
                final status =
                    ref.read(achievementProvider.notifier).getAchievementStatus(a.id);
                final locked = status == AchievementStatus.locked;
                return RadioListTile<String>(
                  value: a.id,
                  title: Text(a.title),
                  subtitle: Text('${a.xpValue} XP • ${a.category.name}'),
                  enabled: locked,
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          // ── Proof image section ─────────────────────────────
          Text('Proof (optional):', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          if (_proofImagePath != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(_proofImagePath!),
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _pickProofImage,
                icon: const Icon(Icons.camera_alt_outlined),
                label: Text(_proofImagePath != null ? 'Change Image' : 'Add Proof Image'),
              ),
              if (_proofImagePath != null) ...[
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => setState(() => _proofImagePath = null),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                  child: const Text('Remove'),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: (_selectedId != null && !_isUploading) ? _submit : null,
            icon: _isUploading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.upload),
            label: Text(_isUploading ? 'Uploading...' : 'Submit'),
          ),
          const SizedBox(height: 8),
          Text(
            _proofImagePath != null
                ? 'Your proof image will be uploaded with the submission.'
                : 'No image selected — text-only submission.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
