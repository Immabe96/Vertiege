import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'baseline/baseline_spike_page.dart';

/// Debug-only Forui baseline reference (Wave 0 winner).
@immutable
class SpikeSettingsPage extends StatelessWidget {
  const SpikeSettingsPage({super.key});

  factory SpikeSettingsPage.fromQuery(String? _) => const SpikeSettingsPage();

  @override
  Widget build(BuildContext context) {
    assert(kDebugMode, 'SpikeSettingsPage is debug-only');
    return const BaselineSpikePage();
  }
}
