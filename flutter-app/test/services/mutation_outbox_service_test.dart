import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vertiege/services/mutation_outbox_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('enqueue persists and replays queued mutations', () async {
    await MutationOutboxService.enqueue('post.react', {
      'postId': 'post-1',
      'emoji': 'heart',
      'residentId': 'resident-1',
    });

    final queued = await MutationOutboxService.getAll();
    expect(queued, hasLength(1));
    expect(queued.single.type, 'post.react');

    final replayed = <String>[];
    await MutationOutboxService.replay((mutation) async {
      replayed.add(mutation.type);
    });

    expect(replayed, ['post.react']);
    expect(await MutationOutboxService.getAll(), isEmpty);
  });

  test('replay keeps failed mutations with retry metadata', () async {
    await MutationOutboxService.enqueue('post.comment', {
      'postId': 'post-1',
      'commentId': 'comment-1',
    });

    await MutationOutboxService.replay((_) async {
      throw StateError('offline');
    });

    final queued = await MutationOutboxService.getAll();
    expect(queued, hasLength(1));
    expect(queued.single.retryCount, 1);
    expect(queued.single.error, contains('offline'));
  });
}
