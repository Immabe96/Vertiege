import 'package:flutter_test/flutter_test.dart';
import 'package:vertiege/services/nexus_bento_order.dart';

void main() {
  test('compactShortcutOrder preserves unknown ids', () {
    final order = NexusBentoOrder.compactShortcutOrder([
      'season',
      'quest',
      'custom',
    ]);
    expect(order.first, isIn(NexusBentoOrder.defaultOrder));
    expect(order, contains('custom'));
  });
}
