/// UI Wave 0 spike backends (debug only).
enum SpikeBackend {
  baseline('baseline', 'Forui baseline'),
  shadcnUi('shadcn', 'shadcn_ui'),
  material3('material3', 'Material 3');

  const SpikeBackend(this.id, this.label);

  final String id;
  final String label;

  static SpikeBackend? fromId(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final value in SpikeBackend.values) {
      if (value.id == id) return value;
    }
    return null;
  }
}
