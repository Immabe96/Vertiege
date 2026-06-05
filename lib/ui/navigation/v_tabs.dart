import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

class VTabEntry {
  final Widget label;
  final Widget child;

  const VTabEntry({required this.label, required this.child});
}

/// Managed Forui tabs — use instead of direct [FTabs] in feature screens.
class VTabs extends StatelessWidget {
  final List<VTabEntry> tabs;
  final bool expands;
  final bool scrollable;

  const VTabs({
    super.key,
    required this.tabs,
    this.expands = true,
    this.scrollable = false,
  });

  @override
  Widget build(BuildContext context) {
    return FTabs(
      expands: expands,
      scrollable: scrollable,
      control: const FTabControl.managed(),
      children: [
        for (final tab in tabs)
          FTabEntry(label: tab.label, child: tab.child),
      ],
    );
  }
}
