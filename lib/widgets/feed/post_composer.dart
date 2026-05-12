import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/storage_service.dart';
import '../../state/post_provider.dart';
import '../../state/resident_provider.dart';
import '../../state/world_provider.dart';
import '../../theme/colors.dart';
import '../../theme/design_system.dart';
import '../shared/image_picker_widget.dart';
import '../core/xp_toast.dart';

class PostComposer extends ConsumerStatefulWidget {
  const PostComposer({super.key});

  @override
  ConsumerState<PostComposer> createState() => _PostComposerState();
}

class _PostComposerState extends ConsumerState<PostComposer>
    with SingleTickerProviderStateMixin {
  static const String _draftKey = '@post_composer_draft';
  static const int _maxChars = 500;
  static const int _warnChars = 400;

  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  String? _imageUri;
  bool _isAnnouncement = false;
  bool _sent = false;
  String? _selectedWorldId;
  bool _hasDraft = false;

  late final AnimationController _sendAnim;
  late final Animation<double> _sendScale;

  @override
  void initState() {
    super.initState();
    _sendAnim = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _sendScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.25), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 1.25, end: 0.85), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 0.85, end: 1.0), weight: 70),
    ]).animate(CurvedAnimation(parent: _sendAnim, curve: Curves.easeInOut));

    _loadDraft();
    // Auto-focus after frame so keyboard opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _sendAnim.dispose();
    super.dispose();
  }

  Future<void> _loadDraft() async {
    final raw = await StorageService.getString(_draftKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final text = data['text'] as String? ?? '';
      final imageUri = data['imageUri'] as String?;
      if (text.isNotEmpty || imageUri != null) {
        setState(() {
          _hasDraft = true;
          _controller.text = text;
          _imageUri = imageUri;
        });
      }
    } catch (_) {}
  }

  Future<void> _saveDraft() async {
    final text = _controller.text.trim();
    if (text.isEmpty && _imageUri == null) return;
    await StorageService.setString(
      _draftKey,
      jsonEncode({'text': text, 'imageUri': _imageUri}),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Draft saved'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          width: 140,
          backgroundColor: AppColors.surfaceHigh,
        ),
      );
    }
  }

  Future<void> _discardDraft() async {
    await StorageService.remove(_draftKey);
    setState(() {
      _hasDraft = false;
      _controller.clear();
      _imageUri = null;
    });
  }

  Future<void> _submit() async {
    final content = _controller.text.trim();
    if (content.isEmpty) return;

    final resident = ref.read(residentProvider).resident;
    if (resident == null) return;

    final joinedWorlds = ref
        .read(worldProvider)
        .worlds
        .values
        .where((w) => resident.joinedWorldIds.contains(w.id))
        .toList();
    final targetWorldId =
        _selectedWorldId ??
        (joinedWorlds.isNotEmpty ? joinedWorlds.first.id : null);
    if (targetWorldId == null) return;
    final imageUri = _imageUri;
    final isAnnouncement = _isAnnouncement;

    _controller.clear();
    setState(() {
      _imageUri = null;
      _isAnnouncement = false;
      _sent = true;
      _hasDraft = false;
    });
    _sendAnim.forward(from: 0);
    HapticFeedback.heavyImpact();
    XpToast.show(context, amount: 15);
    StorageService.remove(_draftKey);

    try {
      await ref
          .read(postProvider.notifier)
          .addPost(
            worldId: targetWorldId,
            residentId: resident.id,
            residentName: resident.name,
            residentAvatar: resident.avatarUrl,
            content: content,
            imageUri: imageUri,
            tierValue: resident.tier.value,
            isAnnouncement: isAnnouncement,
          );
    } catch (_) {
      // Post failed — the provider will have reverted the optimistic update
      if (mounted) {
        setState(() => _sent = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to publish post. Please try again.'),
          ),
        );
      }
      return;
    }

    if (mounted) {
      setState(() => _sent = false);
      Navigator.of(context).pop();
    }
  }

  Color _charColor(int length) {
    if (length >= _maxChars) return AppColors.semanticError;
    if (length >= _warnChars) return AppColors.accentStreak;
    return AppColors.inkMuted;
  }

  @override
  Widget build(BuildContext context) {
    final resident = ref.watch(residentProvider).resident;
    final worlds = ref
        .watch(worldProvider)
        .worlds
        .values
        .where((w) => resident?.joinedWorldIds.contains(w.id) ?? false)
        .toList();
    final canAnnounce = resident != null && worlds.isNotEmpty;

    final charLength = _controller.text.length;
    final charColor = _charColor(charLength);
    final charProgress = (charLength / _maxChars).clamp(0.0, 1.0);

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Drag handle ──────────────────────────────
            Center(
              child: Container(
                margin: const EdgeInsets.only(
                  top: Spacing.sm,
                  bottom: Spacing.xs,
                ),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.inkMuted.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(RadiusTokens.full),
                ),
              ),
            ),

            // ── Header ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
              child: Row(
                children: [
                  Text(
                    'Create Post',
                    style: const TextStyle(
                      fontSize: FontSizes.headingCard,
                      fontWeight: FontWeights.bold,
                      color: AppColors.ink,
                    ),
                  ),
                  const Spacer(),
                  // Draft indicator
                  if (_hasDraft)
                    Padding(
                      padding: const EdgeInsets.only(right: Spacing.sm),
                      child: TextButton.icon(
                        onPressed: _discardDraft,
                        icon: const Icon(
                          Icons.delete_outline,
                          size: IconSizes.sm,
                        ),
                        label: const Text(
                          'Discard',
                          style: TextStyle(
                            fontSize: FontSizes.caption,
                            color: AppColors.semanticError,
                          ),
                        ),
                      ),
                    ),
                  // Close
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, size: IconSizes.md),
                    color: AppColors.inkMuted,
                    splashRadius: TouchTargets.iconButton / 2,
                  ),
                ],
              ),
            ),

            const SizedBox(height: Spacing.sm),

            // ── World selector chips ─────────────────────
            if (worlds.length > 1)
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
                  itemCount: worlds.length,
                  separatorBuilder: (_, _) => const SizedBox(width: Spacing.sm),
                  itemBuilder: (context, i) {
                    final world = worlds[i];
                    final selected =
                        _selectedWorldId == world.id ||
                        (_selectedWorldId == null && i == 0);
                    return GestureDetector(
                      onTap: () => setState(() => _selectedWorldId = world.id),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Spacing.md,
                          vertical: Spacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary.withValues(
                                  alpha: AppColors.alphaSelected,
                                )
                              : AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(
                            RadiusTokens.pill,
                          ),
                          border: Border.all(
                            color: selected
                                ? AppColors.primary.withValues(
                                    alpha: AppColors.alphaBorder,
                                  )
                                : AppColors.glassBorder,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.public,
                              size: IconSizes.xs,
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.inkSecondary,
                            ),
                            const SizedBox(width: Spacing.xs),
                            Text(
                              world.name,
                              style: TextStyle(
                                fontSize: FontSizes.caption,
                                fontWeight: selected
                                    ? FontWeights.bold
                                    : FontWeights.regular,
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.inkSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: Spacing.md),

            // ── Main text area ────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                maxLines: 5,
                minLines: 3,
                maxLength: _maxChars,
                buildCounter:
                    (
                      context, {
                      required currentLength,
                      required isFocused,
                      maxLength,
                    }) {
                      return null;
                    },
                style: const TextStyle(
                  fontSize: FontSizes.body,
                  fontWeight: FontWeights.regular,
                  color: AppColors.ink,
                  height: LineHeight.body,
                ),
                decoration: InputDecoration(
                  hintText: "What's happening in your world?",
                  hintStyle: const TextStyle(
                    fontSize: FontSizes.body,
                    fontWeight: FontWeights.regular,
                    color: AppColors.inkMuted,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  filled: false,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),

            // ── Image preview ─────────────────────────────
            if (_imageUri != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Spacing.lg,
                  0,
                  Spacing.lg,
                  Spacing.sm,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(RadiusTokens.card),
                  child: Stack(
                    children: [
                      _ImagePreview(
                        uri: _imageUri!,
                        height: 160,
                        width: double.infinity,
                      ),
                      Positioned(
                        top: Spacing.sm,
                        right: Spacing.sm,
                        child: GestureDetector(
                          onTap: () => setState(() => _imageUri = null),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: AppColors.canvas.withValues(alpha: 0.8),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: Spacing.md),

            // ── Bottom toolbar ────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
              child: Row(
                children: [
                  // ── Image attach ──────────────────────
                  ImagePickerWidget(
                    onImageSelected: (uri) => setState(() => _imageUri = uri),
                  ),

                  const SizedBox(width: Spacing.xs),

                  // ── Save draft ────────────────────────
                  _CompactTool(
                    icon: Icons.drafts_outlined,
                    tooltip: 'Save draft',
                    onTap:
                        _controller.text.trim().isNotEmpty || _imageUri != null
                        ? _saveDraft
                        : null,
                  ),

                  // ── Announcement toggle ───────────────
                  if (canAnnounce)
                    _CompactTool(
                      icon: Icons.campaign,
                      tooltip: 'Announcement',
                      active: _isAnnouncement,
                      onTap: () =>
                          setState(() => _isAnnouncement = !_isAnnouncement),
                    ),

                  const Spacer(),

                  // ── Character counter ─────────────────
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: charProgress,
                          strokeWidth: 2.5,
                          backgroundColor: AppColors.surfaceElevated,
                          valueColor: AlwaysStoppedAnimation(charColor),
                        ),
                        Text(
                          '${_maxChars - charLength}',
                          style: TextStyle(
                            fontSize: FontSizes.micro,
                            fontWeight: FontWeights.bold,
                            color: charColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: Spacing.sm),

                  // ── Send button ────────────────────────
                  ScaleTransition(
                    scale: _sendScale,
                    child: GestureDetector(
                      onTap:
                          (_sent || charLength > _maxChars || charLength == 0)
                          ? null
                          : _submit,
                      child: AnimatedContainer(
                        duration: AnimDurations.fast,
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: charLength > 0
                              ? AppColors.primary
                              : AppColors.surfaceElevated,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _sent ? Icons.check : Icons.arrow_upward,
                          size: IconSizes.md,
                          color: charLength > 0
                              ? AppColors.inkOnAccent
                              : AppColors.inkMuted,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: Spacing.md),
          ],
        ),
      ),
    );
  }
}

// ── Compact toolbar button ────────────────────────────────

class _CompactTool extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool active;

  const _CompactTool({
    required this.icon,
    required this.tooltip,
    this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: active
                ? AppColors.primary.withValues(alpha: AppColors.alphaSelected)
                : null,
            borderRadius: BorderRadius.circular(RadiusTokens.circle),
          ),
          child: Icon(
            icon,
            size: IconSizes.sm,
            color: active ? AppColors.primary : AppColors.inkSecondary,
          ),
        ),
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  final String uri;
  final double height;
  final double width;

  const _ImagePreview({
    required this.uri,
    required this.height,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    if (uri.startsWith('http')) {
      return Image.network(
        uri,
        height: height,
        width: width,
        fit: BoxFit.cover,
      );
    }
    return Image.file(
      File(uri),
      height: height,
      width: width,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Container(
        height: height,
        width: width,
        color: AppColors.surfaceHigh,
        alignment: Alignment.center,
        child: const Icon(Icons.broken_image, color: AppColors.inkMuted),
      ),
    );
  }
}
