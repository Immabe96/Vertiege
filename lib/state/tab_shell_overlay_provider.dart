import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Blocks tab-shell chrome (compose FAB) while sheets/modals are open.
class TabShellOverlayNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void acquire() => state++;

  void release() {
    if (state > 0) state--;
  }
}

final tabShellOverlayProvider =
    NotifierProvider<TabShellOverlayNotifier, int>(
  TabShellOverlayNotifier.new,
);
