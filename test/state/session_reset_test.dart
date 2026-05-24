import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vertiege/services/mutation_outbox_service.dart';
import 'package:vertiege/services/storage_service.dart';
import 'package:vertiege/state/session_reset.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('clearUserPersistedSessionData removes outbox and session caches', () async {
    await MutationOutboxService.enqueue('post.react', {
      'postId': 'post-1',
      'residentId': 'resident-a',
    });
    await StorageService.setString(StorageService.residentKey, '{"id":"resident-a"}');
    await StorageService.setString(
      StorageService.chatMessagesKey,
      '{"room-1":[]}',
    );
    await StorageService.setString('@worlds_cache', '[]');

    await clearUserPersistedSessionData();

    expect(await MutationOutboxService.getAll(), isEmpty);
    expect(await StorageService.getString(StorageService.residentKey), isNull);
    expect(await StorageService.getString(StorageService.chatMessagesKey), isNull);
    expect(await StorageService.getString('@worlds_cache'), isNull);
  });

  test('clearUserPersistedSessionData does not remove theme preference', () async {
    await StorageService.setString(StorageService.themeKey, 'dark');
    await StorageService.setString(StorageService.residentKey, '{}');

    await clearUserPersistedSessionData();

    expect(await StorageService.getString(StorageService.themeKey), 'dark');
  });
}
