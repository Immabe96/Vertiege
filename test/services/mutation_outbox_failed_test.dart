import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vertiege/services/mutation_outbox_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('getFailed returns items at max retries', () async {
    await MutationOutboxService.enqueue('post.react', {'postId': 'p1'});
    for (var i = 0; i < MutationOutboxService.maxRetries; i++) {
      await MutationOutboxService.replay((_) async {
        throw StateError('offline');
      });
    }

    final failed = await MutationOutboxService.getFailed();
    expect(failed, hasLength(1));
    expect(failed.single.retryCount, MutationOutboxService.maxRetries);
  });

  test('discardFailed removes only dead-letter items', () async {
    await MutationOutboxService.enqueue('post.react', {'postId': 'p1'});
    await MutationOutboxService.enqueue('post.react', {'postId': 'p2'});
    for (var i = 0; i < MutationOutboxService.maxRetries; i++) {
      await MutationOutboxService.replay((_) async {
        throw StateError('offline');
      });
    }

    await MutationOutboxService.discardFailed();
    expect(await MutationOutboxService.getFailed(), isEmpty);
    final remaining = await MutationOutboxService.getAll();
    expect(remaining, isEmpty);
  });
}
