import '../../core/error/failures.dart';
import '../../core/error/result.dart';
import '../../core/utils/app_logger.dart';
import '../../domain/repositories/reset_repository.dart';
import '../../domain/services/streak_milestones.dart';
import '../local/daos/reset_dao.dart';

/// Runs parent-controlled resets via [ResetDao]'s `@transaction` methods —
/// each one either fully applies or leaves the database untouched.
final class ResetRepositoryImpl implements ResetRepository {
  const ResetRepositoryImpl(this._resetDao);

  final ResetDao _resetDao;

  @override
  Future<Result<void>> resetLearningProgress() async {
    try {
      await _resetDao.resetLearningProgress(StreakMilestones.ownerId);
      return const Success(null);
    } catch (e, st) {
      AppLogger.error('resetLearningProgress failed', error: e, stackTrace: st);
      return Failure(DatabaseFailure('Could not reset learning progress.', cause: e, stackTrace: st));
    }
  }

  @override
  Future<Result<void>> resetSingleModule(String moduleId) async {
    try {
      await _resetDao.resetSingleModule(moduleId);
      return const Success(null);
    } catch (e, st) {
      AppLogger.error('resetSingleModule failed for "$moduleId"', error: e, stackTrace: st);
      return Failure(DatabaseFailure('Could not reset that adventure.', cause: e, stackTrace: st));
    }
  }

  @override
  Future<Result<void>> resetEverything() async {
    try {
      await _resetDao.resetEverything();
      return const Success(null);
    } catch (e, st) {
      AppLogger.error('resetEverything failed', error: e, stackTrace: st);
      return Failure(DatabaseFailure('Could not reset everything.', cause: e, stackTrace: st));
    }
  }
}
