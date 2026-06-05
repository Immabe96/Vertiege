import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'baseline/baseline_spike_page.dart';
import 'material3/material3_spike_page.dart';
import 'shadcn_ui/shadcn_spike_page.dart';
import 'spike_backend.dart';
import 'spike_settings_model.dart';

/// Debug-only Wave 0 spike orchestrator (three UI backends).
@immutable
class SpikeSettingsPage extends StatefulWidget {
  final SpikeBackend initialBackend;

  const SpikeSettingsPage({
    super.key,
    this.initialBackend = SpikeBackend.baseline,
  });

  factory SpikeSettingsPage.fromQuery(String? backendId) {
    return SpikeSettingsPage(
      initialBackend: SpikeBackend.fromId(backendId) ?? SpikeBackend.baseline,
    );
  }

  @override
  State<SpikeSettingsPage> createState() => _SpikeSettingsPageState();
}

class _SpikeSettingsPageState extends State<SpikeSettingsPage> {
  late final SpikeSettingsModel _model = SpikeSettingsModel();
  late SpikeBackend _backend = widget.initialBackend;

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  void _setBackend(SpikeBackend backend) {
    if (_backend == backend) return;
    setState(() => _backend = backend);
  }

  @override
  Widget build(BuildContext context) {
    assert(kDebugMode, 'SpikeSettingsPage is debug-only');
    return switch (_backend) {
      SpikeBackend.baseline => BaselineSpikePage(
        model: _model,
        backend: _backend,
        onBackendChanged: _setBackend,
      ),
      SpikeBackend.shadcnUi => ShadcnSpikePage(
        model: _model,
        backend: _backend,
        onBackendChanged: _setBackend,
      ),
      SpikeBackend.material3 => Material3SpikePage(
        model: _model,
        backend: _backend,
        onBackendChanged: _setBackend,
      ),
    };
  }
}
