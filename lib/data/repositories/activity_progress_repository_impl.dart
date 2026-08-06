import '../../core/error/failures.dart';
import '../../core/error/result.dart';
import '../../core/utils/app_logger.dart';
import '../../domain/repositories/activity_progress_repository.dart';
import '../local/daos/activity_progress_dao.dart';
import '../local/entities/activity_progress_entity.dart';

/// Persists activity completion via Floor. Never stores static content —
/// only whether an activity has been completed.
final class ActivityProgressRepositoryImpl implements ActivityProgressRepository {
  const ActivityProgressRepositoryImpl(this._dao);

  final ActivityProgressDao _dao;

  @override
  Future<Result<bool>> isActivityCompleted(String activityId) async {
    try {
      final row = await _dao.findByActivity(activityId);
      return Success(row?.isCompleted ?? false);
    } catch (e, st) {
      AppLogger.error('isActivityCompleted failed for "$activityId"', error: e, stackTrace: st);
      return Failure(DatabaseFailure('Could not load your progress.', cause: e, stackTrace: st));
    }
  }

  @override
  Future<Result<void>> markActivityCompleted(String activityId) async {
    try {
      await _dao.insertOrUpdate(
        ActivityProgressEntity(
          activityId: activityId,
          isCompleted: true,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );
      return const Success(null);
    } catch (e, st) {
      AppLogger.error('markActivityCompleted failed for "$activityId"', error: e, stackTrace: st);
      return Failure(DatabaseFailure('Could not save your progress.', cause: e, stackTrace: st));
    }
  }
}
