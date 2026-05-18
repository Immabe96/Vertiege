import '../models/notification.dart';
import '../models/repository_result.dart';
import '../services/notification_service.dart';

class NotificationRepository {
  const NotificationRepository();

  Future<RepositoryResult<void>> create(
    AppNotification notification,
    String recipientId,
  ) async {
    try {
      await NotificationService.createNotification(
        notification: notification,
        recipientId: recipientId,
      );
      return const RepositoryResult.success(null);
    } catch (error, stackTrace) {
      return RepositoryResult.failure(error, stackTrace);
    }
  }
}
