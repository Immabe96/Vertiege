import '../models/repository_result.dart';
import '../models/resident.dart';
import '../services/mutation_outbox_service.dart';
import '../services/profile_service.dart';
import '../services/world_service.dart';
import '../services/supabase.dart';

class WorldRepository {
  const WorldRepository();

  static const joinWorldMutation = 'world.join';
  static const leaveWorldMutation = 'world.leave';

  Future<RepositoryResult<void>> joinWorld({
    required String worldId,
    required String residentId,
    required String residentName,
  }) async {
    if (!WorldService.isRemoteWorldId(worldId)) {
      return const RepositoryResult.success(null);
    }
    if (!isSupabaseConfigured()) {
      await MutationOutboxService.enqueue(joinWorldMutation, {
        'worldId': worldId,
        'residentId': residentId,
        'residentName': residentName,
      });
      return const RepositoryResult.queued();
    }

    try {
      await WorldService.joinWorld(
        worldId,
        residentId,
        residentName: residentName,
      );
      return const RepositoryResult.success(null);
    } catch (error, stackTrace) {
      await MutationOutboxService.enqueue(joinWorldMutation, {
        'worldId': worldId,
        'residentId': residentId,
        'residentName': residentName,
      });
      return RepositoryResult.failure(error, stackTrace);
    }
  }

  Future<RepositoryResult<void>> leaveWorld({
    required String worldId,
    required String residentId,
  }) async {
    if (!WorldService.isRemoteWorldId(worldId)) {
      return const RepositoryResult.success(null);
    }
    if (!isSupabaseConfigured()) {
      await MutationOutboxService.enqueue(leaveWorldMutation, {
        'worldId': worldId,
        'residentId': residentId,
      });
      return const RepositoryResult.queued();
    }

    try {
      await WorldService.leaveWorld(worldId, residentId);
      return const RepositoryResult.success(null);
    } catch (error, stackTrace) {
      await MutationOutboxService.enqueue(leaveWorldMutation, {
        'worldId': worldId,
        'residentId': residentId,
      });
      return RepositoryResult.failure(error, stackTrace);
    }
  }

  Future<void> replayOutbox() async {
    await MutationOutboxService.replay((mutation) async {
      switch (mutation.type) {
        case joinWorldMutation:
          await WorldService.joinWorld(
            mutation.payload['worldId'] as String,
            mutation.payload['residentId'] as String,
            residentName:
                mutation.payload['residentName'] as String? ?? 'Member',
          );
          break;
        case leaveWorldMutation:
          await WorldService.leaveWorld(
            mutation.payload['worldId'] as String,
            mutation.payload['residentId'] as String,
          );
          break;
      }
    });
  }

  Future<RepositoryResult<void>> saveProfileMembership(
    Resident resident,
  ) async {
    try {
      await ProfileService.upsertProfile(resident);
      return const RepositoryResult.success(null);
    } catch (error, stackTrace) {
      return RepositoryResult.failure(error, stackTrace);
    }
  }
}
