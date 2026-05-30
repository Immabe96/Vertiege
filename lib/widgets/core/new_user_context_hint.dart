import 'package:flutter/material.dart';

import '../../services/contextual_help_prefs.dart';
import '../worlds/world_capability_hint.dart';

/// Inline help banner — only for users still in the first-steps funnel.
class NewUserContextHint extends StatelessWidget {
  final String message;
  final IconData icon;
  final String? surfaceId;

  const NewUserContextHint({
    super.key,
    required this.message,
    this.icon = Icons.info_outline,
    this.surfaceId,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _visible(),
      builder: (context, snapshot) {
        if (snapshot.data != true) return const SizedBox.shrink();
        return WorldCapabilityHint(message: message, icon: icon);
      },
    );
  }

  Future<bool> _visible() async {
    if (!await ContextualHelpPrefs.shouldShowContextualHelp()) {
      return false;
    }
    final id = surfaceId;
    if (id == null) return true;
    return !await ContextualHelpPrefs.isSurfaceHintDismissed(id);
  }
}
