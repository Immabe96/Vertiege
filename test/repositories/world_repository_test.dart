import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vertiege/repositories/world_repository.dart';
import 'package:vertiege/services/mutation_outbox_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'joinWorld queues remote membership when Supabase is unavailable',
    () async {
      const repository = WorldRepository();

      final result = await repository.joinWorld(
        worldId: '11111111-1111-4111-8111-111111111111',
        residentId: '22222222-2222-4222-8222-222222222222',
        residentName: 'Ari',
      );

      expect(result.queued, isTrue);

      final outbox = await MutationOutboxService.getAll();
      expect(outbox, hasLength(1));
      expect(outbox.single.type, WorldRepository.joinWorldMutation);
      expect(outbox.single.payload['worldId'], contains('11111111'));
    },
  );

  test('joinWorld does not queue local starter world ids', () async {
    const repository = WorldRepository();

    final result = await repository.joinWorld(
      worldId: 'nexus',
      residentId: 'resident-1',
      residentName: 'Ari',
    );

    expect(result.isSuccess, isTrue);
    expect(await MutationOutboxService.getAll(), isEmpty);
  });
}
