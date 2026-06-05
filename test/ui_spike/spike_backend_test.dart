import 'package:flutter_test/flutter_test.dart';
import 'package:vertiege/ui_spike/spike_backend.dart';

void main() {
  test('SpikeBackend.fromId resolves query param aliases', () {
    expect(SpikeBackend.fromId('baseline'), SpikeBackend.baseline);
    expect(SpikeBackend.fromId('shadcn'), SpikeBackend.shadcnUi);
    expect(SpikeBackend.fromId('material3'), SpikeBackend.material3);
    expect(SpikeBackend.fromId(null), isNull);
    expect(SpikeBackend.fromId('unknown'), isNull);
  });
}
