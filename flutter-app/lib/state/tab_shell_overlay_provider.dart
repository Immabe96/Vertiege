import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tab_shell_overlay_provider.g.dart';

/// Blocks tab-shell chrome (compose FAB) while sheets/modals are open.
@Riverpod(name: 'tabShellOverlayProvider', keepAlive: true)
class TabShellOverlayNotifier extends _$TabShellOverlayNotifier {
  @override
  int build() => 0;

  void acquire() => state++;

  void release() {
    if (state > 0) state--;
  }
}
