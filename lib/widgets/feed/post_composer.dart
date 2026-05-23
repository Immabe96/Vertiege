import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/storage_service.dart';
import '../../state/post_provider.dart';
import '../../state/resident_provider.dart';
import '../../state/world_provider.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../../theme/v_tokens.dart';
import '../shared/image_picker_widget.dart';
import '../core/xp_toast.dart';
import '../../ui/icons/v_icons.dart';

class PostComposer extends ConsumerStatefulWidget {
  const PostComposer({super.key});

  @override
  ConsumerState<PostComposer> createState() => _PostComposerState();
}

class _PostComposerState extends ConsumerState<PostComposer>
    with SingleTickerProviderStateMixin {
  static const int _maxChars = 500;
  static const int _warnChars = 400;

  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  String? _imageUri;
  bool _isAnnouncement = false;
  bool _sent = false;
  String? _selectedWorldId;
  bool _hasDraft = false;
  DateTime? _scheduledFor;

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

  String get _draftKey {
    final residentId = ref.read(residentProvider).resident?.id ?? 'anon';
    final worldId = _selectedWorldId ?? 'default';
    return '@post_composer_draft:$residentId:$worldId';
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
          backgroundColor: VColors.surfaceContainerHighest,
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

  Future<void> _pickSchedule() async {
    final now = DateTime.now();
    final minDate = now.add(const Duration(minutes: 5));
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: minDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(minDate),
    );
    if (pickedTime == null || !mounted) return;

    final scheduled = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    if (scheduled.isBefore(now)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Schedule time must be in the future'),
          ),
        );
      }
      return;
    }

    setState(() => _scheduledFor = scheduled);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Scheduled for ${_formatScheduleDate(scheduled)}',
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: VColors.surfaceContainerHighest,
        ),
      );
    }
  }

  String _formatScheduleDate(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${months[dt.month - 1]} ${dt.day} ${dt.year} at $hour:${dt.minute.toString().padLeft(2, '0')} $ampm';
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
    final scheduledFor = _scheduledFor;

    // B-13 FIX: Save content for rollback before clearing
    final savedContent = content;
    final savedImageUri = imageUri;
    final savedAnnouncement = isAnnouncement;
    final savedScheduledFor = scheduledFor;

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
            scheduledFor: scheduledFor,
          );

      // Only clear UI and show success AFTER post succeeds
      _controller.clear();
      setState(() {
        _imageUri = null;
        _isAnnouncement = false;
        _sent = true;
        _hasDraft = false;
        _scheduledFor = null;
      });
      _sendAnim.forward(from: 0);
      HapticFeedback.heavyImpact();
      XpToast.show(context, amount: 15);
      StorageService.remove(_draftKey);

      if (mounted) {
        setState(() => _sent = false);
        Navigator.of(context).pop();
      }
    } catch (e) {
      // B-13 FIX: Restore content on failure
      if (mounted) {
        _controller.text = savedContent;
        setState(() {
          _imageUri = savedImageUri;
          _isAnnouncement = savedAnnouncement;
          _scheduledFor = savedScheduledFor;
          _sent = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to publish post. Please try again.'),
            backgroundColor: VColors.error,
          ),
        );
      }
    }
  }

  Color _charColor(int length) {
    if (length >= _maxChars) return VColors.error;
    if (length >= _warnChars) return VColors.secondary;
    return VColors.outline;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                  top: VSpacing.sm,
                  bottom: VSpacing.xs,
                ),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: (isDark ? VColors.onSurfaceVariantDark : VColors.outline).withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(VRadius.pill),
                ),
              ),
            ),

            // ── Header ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: VSpacing.lg),
              child: Row(
                children: [
                  Text(
                    'Create Post',
                    style: TextStyle(
                      fontSize: VFontSize.headlineMd,
                      fontWeight: VFontWeight.bold,
                      color: isDark ? VColors.onSurfaceDark : VColors.onSurface,
                    ),
                  ),
                  const Spacer(),
                  // Draft indicator
                  if (_hasDraft)
                    Padding(
                      padding: const EdgeInsets.only(right: VSpacing.sm),
                      child: TextButton.icon(
                        onPressed: _discardDraft,
                        icon: const Icon(
                          Icons.delete_outline,
                          size: VIconSize.sm,
                        ),
                        label: const Text(
                          'Discard',
                          style: TextStyle(
                            fontSize: VFontSize.labelMd,
                            color: VColors.error,
                          ),
                        ),
                      ),
                    ),
                  // Close
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(VIcons.x, size: VIconSize.md),
                    color: VColors.outline,
                    splashRadius: VTouchTarget.iconButton / 2,
                  ),
                ],
              ),
            ),

            const SizedBox(height: VSpacing.sm),

            // ── World selector chips ─────────────────────
            if (worlds.length > 1)
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: VSpacing.lg),
                  itemCount: worlds.length,
                  separatorBuilder: (_, _) => const SizedBox(width: VSpacing.sm),
                  itemBuilder: (context, i) {
                    final world = worlds[i];
                    final selected =
                        _selectedWorldId == world.id ||
                        (_selectedWorldId == null && i == 0);
                    return GestureDetector(
                      onTap: () => setState(() => _selectedWorldId = world.id),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: VSpacing.md,
                          vertical: VSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? VColors.primary.withValues(
                                  alpha: 0.16,
                                )
                              : VColors.surfaceBright,
                          borderRadius: BorderRadius.circular(
                            VRadius.pill,
                          ),
                          border: Border.all(
                            color: selected
                                ? VColors.primary.withValues(
                                    alpha: 0.2,
                                  )
                                : VColors.glassBorder,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.public,
                              size: VIconSize.xs,
                              color: selected
                                  ? VColors.primary
                                  : VColors.onSurfaceVariant,
                            ),
                            const SizedBox(width: VSpacing.xs),
                            Text(
                              world.name,
                              style: TextStyle(
                                fontSize: VFontSize.labelMd,
                                fontWeight: selected
                                    ? VFontWeight.bold
                                    : VFontWeight.regular,
                                color: selected
                                    ? VColors.primary
                                    : VColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: VSpacing.md),

            // ── Main text area ────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: VSpacing.lg),
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
                  fontSize: VFontSize.bodyMd,
                  fontWeight: VFontWeight.regular,
                  color: VColors.onSurface,
                  height: VLineHeight.body,
                ),
                decoration: InputDecoration(
                  hintText: "What's happening in your world?",
                  hintStyle: const TextStyle(
                    fontSize: VFontSize.bodyMd,
                    fontWeight: VFontWeight.regular,
                    color: VColors.outline,
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
                  VSpacing.lg,
                  0,
                  VSpacing.lg,
                  VSpacing.sm,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(VRadius.lg),
                  child: Stack(
                    children: [
                      _ImagePreview(
                        uri: _imageUri!,
                        height: 160,
                        width: double.infinity,
                      ),
                      Positioned(
                        top: VSpacing.sm,
                        right: VSpacing.sm,
                        child: GestureDetector(
                          onTap: () => setState(() => _imageUri = null),
                          child: Container(
                            width: VTouchTarget.iconButton,
                            height: VTouchTarget.iconButton,
                            decoration: BoxDecoration(
                              color: VColors.surface.withValues(alpha: 0.8),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: VIconSize.md,
                              color: VColors.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: VSpacing.md),

            // ── Bottom toolbar ────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: VSpacing.lg),
              child: Row(
                children: [
                  // ── Image attach ──────────────────────
                  ImagePickerWidget(
                    onImageSelected: (uri) => setState(() => _imageUri = uri),
                  ),

                  const SizedBox(width: VSpacing.xs),

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

                  // ── Schedule ──────────────────────────
                  _CompactTool(
                    icon: _scheduledFor != null
                        ? Icons.schedule
                        : Icons.schedule_outlined,
                    tooltip: _scheduledFor != null
                        ? 'Scheduled: ${_formatScheduleDate(_scheduledFor!)}'
                        : 'Schedule post',
                    active: _scheduledFor != null,
                    onTap: _pickSchedule,
                  ),

                  const Spacer(),

                  // ── Character counter ─────────────────
                  SizedBox(
                    width: VTouchTarget.minimum,
                    height: VTouchTarget.minimum,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: charProgress,
                          strokeWidth: 2.5,
                          backgroundColor: VColors.surfaceBright,
                          valueColor: AlwaysStoppedAnimation(charColor),
                        ),
                        Text(
                          '${_maxChars - charLength}',
                          style: TextStyle(
                            fontSize: VFontSize.labelSm,
                            fontWeight: VFontWeight.bold,
                            color: charColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: VSpacing.sm),

                  // ── Send button ────────────────────────
                  ScaleTransition(
                    scale: _sendScale,
                    child: GestureDetector(
                      onTap:
                          (_sent || charLength > _maxChars || charLength == 0)
                          ? null
                          : _submit,
                      child: AnimatedContainer(
                        duration: VAnimation.fast,
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: charLength > 0
                              ? VColors.primary
                              : VColors.surfaceBright,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _sent ? Icons.check : Icons.arrow_upward,
                          size: VIconSize.md,
                          color: charLength > 0
                              ? VColors.onPrimary
                              : VColors.outline,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: VSpacing.md),
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
          width: VTouchTarget.iconButton,
          height: VTouchTarget.iconButton,
          decoration: BoxDecoration(
            color: active
                ? VColors.primary.withValues(alpha: 0.16)
                : null,
            borderRadius: BorderRadius.circular(VRadius.pill),
          ),
          child: Icon(
            icon,
            size: VIconSize.md,
            color: active ? VColors.primary : VColors.onSurfaceVariant,
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
        color: VColors.surfaceContainerHighest,
        alignment: Alignment.center,
        child: const Icon(Icons.broken_image, color: VColors.outline),
      ),
    );
  }
}
