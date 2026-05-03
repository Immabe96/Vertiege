import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/permission_service.dart';
import '../../services/storage_service.dart';
import '../../state/post_provider.dart';
import '../../state/resident_provider.dart';
import '../../state/world_provider.dart';
import '../../theme/design_system.dart';
import '../shared/image_picker_widget.dart';

class PostInput extends ConsumerStatefulWidget {
  final String worldId;
  final String? sovereignId;
  final bool showWorldSelector;

  const PostInput({
    super.key,
    required this.worldId,
    this.sovereignId,
    this.showWorldSelector = false,
  });

  @override
  ConsumerState<PostInput> createState() => _PostInputState();
}

class _PostInputState extends ConsumerState<PostInput> with SingleTickerProviderStateMixin {
  static const String _draftKey = '@post_draft';
  static const int _maxChars = 500;
  static const int _warnChars = 400;

  final _controller = TextEditingController();
  String? _imageUri;
  bool _isAnnouncement = false;
  bool _sent = false;
  String? _selectedWorldId;
  late final AnimationController _sendAnim;
  late final Animation<double> _sendScale;

  bool _hasDraft = false;

  @override
  void initState() {
    super.initState();
    _sendAnim = AnimationController(duration: const Duration(milliseconds: 400), vsync: this);
    _sendScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 0.9), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 60),
    ]).animate(CurvedAnimation(parent: _sendAnim, curve: Curves.easeInOut));

    _selectedWorldId = widget.showWorldSelector ? null : widget.worldId;
    _loadDraft();
  }

  @override
  void dispose() {
    _controller.dispose();
    _sendAnim.dispose();
    super.dispose();
  }

  // ── Drafts ─────────────────────────────────────────────────

  Future<void> _loadDraft() async {
    final raw = await StorageService.getString(_draftKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final text = data['text'] as String? ?? '';
      final imageUri = data['imageUri'] as String?;
      if (text.isNotEmpty) {
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
    final data = jsonEncode({
      'text': text,
      'imageUri': _imageUri,
    });
    await StorageService.setString(_draftKey, data);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Draft saved'), duration: Duration(seconds: 1)),
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

  void _continueDraft() {
    setState(() => _hasDraft = false);
  }

  // ── Submit ─────────────────────────────────────────────────

  void _submit() {
    final content = _controller.text.trim();
    if (content.isEmpty) return;

    final resident = ref.read(residentProvider).resident;
    if (resident == null) return;

    final targetWorldId = _selectedWorldId ?? widget.worldId;

    ref.read(postProvider.notifier).addPost(
          worldId: targetWorldId,
          residentId: resident.id,
          residentName: resident.name,
          residentAvatar: resident.avatarUrl,
          content: content,
          imageUri: _imageUri,
          tierValue: resident.tier.value,
          isAnnouncement: _isAnnouncement,
        );

    _controller.clear();
    _sendAnim.forward(from: 0);
    setState(() {
      _imageUri = null;
      _isAnnouncement = false;
      _sent = true;
      _hasDraft = false;
    });
    StorageService.remove(_draftKey);

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _sent = false);
    });
  }

  // ── Character count ────────────────────────────────────────

  Color _charCountColor(int length) {
    if (length >= _maxChars) return Colors.red;
    if (length >= _warnChars) return Colors.orange;
    return Theme.of(context).colorScheme.outline;
  }

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resident = ref.read(residentProvider).resident;
    final worlds = ref.watch(worldProvider).worlds;
    final canAnnounce = resident != null &&
        WorldPermissions.canAnnounce(resident, widget.worldId, widget.sovereignId);

    final charLength = _controller.text.length;
    final charColor = _charCountColor(charLength);

    return Card(
      margin: const EdgeInsets.all(Spacing.md),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Draft banner ─────────────────────────────────
            if (_hasDraft)
              Container(
                margin: const EdgeInsets.only(bottom: Spacing.sm),
                padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
                decoration: BoxDecoration(
                  color: theme.colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(RadiusTokens.sm),
                ),
                child: Row(
                  children: [
                    Icon(Icons.drafts, size: IconSizes.sm, color: theme.colorScheme.tertiary),
                    const SizedBox(width: Spacing.sm),
                    Expanded(
                      child: Text(
                        'You have a saved draft. Continue?',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.tertiary,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _discardDraft,
                      child: Text('Discard', style: TextStyle(color: theme.colorScheme.error, fontSize: FontSizes.caption)),
                    ),
                    TextButton(
                      onPressed: _continueDraft,
                      child: Text('Continue', style: TextStyle(fontSize: FontSizes.caption, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),

            // ── World selector (Nexus) ─────────────────────────
            if (widget.showWorldSelector && worlds.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: Spacing.sm),
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedWorldId,
                  isDense: true,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(RadiusTokens.sm)),
                    labelText: 'Post to',
                    labelStyle: theme.textTheme.labelSmall,
                  ),
                  items: [
                    DropdownMenuItem<String>(
                      value: null,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.public, size: IconSizes.sm, color: theme.colorScheme.outline),
                          const SizedBox(width: Spacing.xs),
                          Text('My Feed', style: theme.textTheme.labelMedium),
                        ],
                      ),
                    ),
                    ...worlds.values.map((world) => DropdownMenuItem<String>(
                          value: world.id,
                          child: Text(world.name, style: theme.textTheme.labelMedium),
                        )),
                  ],
                  onChanged: (value) => setState(() => _selectedWorldId = value),
                ),
              ),

            // ── Announcement toggle ───────────────────────────
            if (canAnnounce)
              Padding(
                padding: const EdgeInsets.only(bottom: Spacing.sm),
                child: InkWell(
                  borderRadius: BorderRadius.circular(RadiusTokens.sm),
                  onTap: () => setState(() => _isAnnouncement = !_isAnnouncement),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.xs),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(RadiusTokens.sm),
                      color: _isAnnouncement
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surfaceContainerHighest,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.campaign, size: IconSizes.sm, color: _isAnnouncement ? theme.colorScheme.primary : theme.colorScheme.outline),
                        const SizedBox(width: Spacing.xs),
                        Text(
                          'Announcement',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: _isAnnouncement ? theme.colorScheme.primary : theme.colorScheme.outline,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // ── Text input + actions ──────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _controller,
                        maxLines: 3,
                        minLines: 1,
                        maxLength: _maxChars,
                        buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                        decoration: const InputDecoration(
                          hintText: "What's on your mind?",
                          border: OutlineInputBorder(),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      // Character count
                      Padding(
                        padding: const EdgeInsets.only(top: Spacing.xs, left: Spacing.xs),
                        child: AnimatedDefaultTextStyle(
                          duration: AnimDurations.fast,
                          style: theme.textTheme.labelSmall!.copyWith(
                            color: charColor,
                            fontWeight: charLength >= _warnChars ? FontWeight.w600 : FontWeight.normal,
                          ),
                          child: Text('$charLength/$_maxChars'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                Column(
                  children: [
                    // Save draft button
                    IconButton(
                      icon: const Icon(Icons.drafts_outlined),
                      onPressed: _controller.text.trim().isNotEmpty ? _saveDraft : null,
                      tooltip: 'Save draft',
                      iconSize: IconSizes.md,
                      color: theme.colorScheme.outline,
                    ),
                    // Send button
                    ScaleTransition(
                      scale: _sendScale,
                      child: IconButton(
                        icon: Icon(_sent ? Icons.check : Icons.send),
                        onPressed: _sent || charLength > _maxChars ? null : _submit,
                        color: _sent ? Colors.green : theme.colorScheme.primary,
                        iconSize: IconSizes.md,
                      ),
                    ),
                    ImagePickerWidget(
                      onImageSelected: (uri) => setState(() => _imageUri = uri),
                    ),
                  ],
                ),
              ],
            ),

            // ── Image preview ──────────────────────────────────
            if (_imageUri != null) ...[
              const SizedBox(height: Spacing.sm),
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(RadiusTokens.sm),
                    child: Image.network(_imageUri!, height: 80, width: 80, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => setState(() => _imageUri = null),
                      style: IconButton.styleFrom(backgroundColor: theme.colorScheme.error),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
