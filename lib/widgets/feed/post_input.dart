import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/permission_service.dart';
import '../../state/post_provider.dart';
import '../../state/resident_provider.dart';
import '../shared/image_picker_widget.dart';

class PostInput extends ConsumerStatefulWidget {
  final String worldId;
  final String? sovereignId;

  const PostInput({super.key, required this.worldId, this.sovereignId});

  @override
  ConsumerState<PostInput> createState() => _PostInputState();
}

class _PostInputState extends ConsumerState<PostInput> with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  String? _imageUri;
  bool _isAnnouncement = false;
  bool _sent = false;
  late final AnimationController _sendAnim;
  late final Animation<double> _sendScale;

  @override
  void initState() {
    super.initState();
    _sendAnim = AnimationController(duration: const Duration(milliseconds: 400), vsync: this);
    _sendScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 0.9), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 60),
    ]).animate(CurvedAnimation(parent: _sendAnim, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    _sendAnim.dispose();
    super.dispose();
  }

  void _submit() {
    final content = _controller.text.trim();
    if (content.isEmpty) return;

    final resident = ref.read(residentProvider).resident;
    if (resident == null) return;

    ref.read(postProvider.notifier).addPost(
          worldId: widget.worldId,
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
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _sent = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resident = ref.read(residentProvider).resident;
    final canAnnounce = resident != null &&
        WorldPermissions.canAnnounce(resident, widget.worldId, widget.sovereignId);

    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            if (canAnnounce)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => setState(() => _isAnnouncement = !_isAnnouncement),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: _isAnnouncement
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surfaceContainerHighest,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.campaign, size: 16, color: _isAnnouncement ? theme.colorScheme.primary : theme.colorScheme.outline),
                        const SizedBox(width: 6),
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
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    maxLines: 3,
                    minLines: 1,
                    decoration: const InputDecoration(
                      hintText: "What's on your mind?",
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  children: [
                    ScaleTransition(
                      scale: _sendScale,
                      child: IconButton(
                        icon: Icon(_sent ? Icons.check : Icons.send),
                        onPressed: _sent ? null : _submit,
                        color: _sent ? Colors.green : theme.colorScheme.primary,
                      ),
                    ),
                    ImagePickerWidget(
                      onImageSelected: (uri) => setState(() => _imageUri = uri),
                    ),
                  ],
                ),
              ],
            ),
            if (_imageUri != null) ...[
              const SizedBox(height: 8),
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
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
