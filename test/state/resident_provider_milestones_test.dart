import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vertiege/models/resident.dart';
import 'package:vertiege/state/resident_provider.dart';

void main() {
  test('clearForSignOut resets resident state', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(residentProvider.notifier);
    notifier.state = const ResidentState(
      resident: Resident(id: 'u1', name: 'A'),
    );
    notifier.clearForSignOut();
    expect(container.read(residentProvider).resident, isNull);
    expect(container.read(residentProvider).isLoading, isFalse);
  });
}
