import '../models/repository_result.dart';
import '../models/resident.dart';
import '../services/profile_service.dart';

class ProfileRepository {
  const ProfileRepository();

  Future<RepositoryResult<void>> saveResident(Resident resident) async {
    try {
      await ProfileService.upsertProfile(resident);
      return const RepositoryResult.success(null);
    } catch (error, stackTrace) {
      return RepositoryResult.failure(error, stackTrace);
    }
  }
}
