import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vertiege/services/mutation_outbox_service.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await MutationOutboxService.clear();
  });

  test('pendingCount excludes exhausted retries', () async {
    expect(await MutationOutboxService.pendingCount(), 0);
    await MutationOutboxService.enqueue('post.create', {'worldId': 'w1'});
    expect(await MutationOutboxService.pendingCount(), 1);
  });
}
