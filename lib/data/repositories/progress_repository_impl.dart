import '../../core/error/failures.dart';
import '../../core/error/result.dart';
import '../../core/utils/app_logger.dart';
import '../../domain/entities/badge_info.dart';
import '../../domain/repositories/progress_repository.dart';
import '../local/daos/badge_dao.dart';
import '../local/daos/progress_dao.dart';
import '../local/daos/quiz_result_dao.dart';
import '../local/entities/badge_entity.dart';
import '../local/entities/progress_entity.dart';
import '../local/entities/quiz_result_entity.dart';

/// Persists progress/badges/quiz results via Floor. Never stores static
/// content — only which beats/badges/quiz attempts happened.
final class ProgressRepositoryImpl implements ProgressRepository {
  const ProgressRepositoryImpl({
    required ProgressDao progressDao,
    required BadgeDao badgeDao,
    required QuizResultDao quizResultDao,
  })  : _progressDao = progressDao,
        _badgeDao = badgeDao,
        _quizResultDao = quizResultDao;

  final ProgressDao _progressDao;
  final BadgeDao _badgeDao;
  final QuizResultDao _quizResultDao;

  @override
  Future<Result<Set<String>>> getCompletedBeatIds(String moduleId) async {
    try {
      final rows = await _progressDao.findByModule(moduleId);
      return Success(rows.map((row) => row.beatId).toSet());
    } catch (e, st) {
      AppLogger.error('getCompletedBeatIds failed for "$moduleId"', error: e, stackTrace: st);
      return Failure(DatabaseFailure('Could not load your progress.', cause: e, stackTrace: st));
    }
  }

  @override
  Future<Result<void>> markBeatCompleted(String moduleId, String beatId) async {
    try {
      await _progressDao.insertProgress(
        ProgressEntity(
          moduleId: moduleId,
          beatId: beatId,
          completedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );
      return const Success(null);
    } catch (e, st) {
      AppLogger.error('markBeatCompleted failed for "$moduleId"/"$beatId"', error: e, stackTrace: st);
      return Failure(DatabaseFailure('Could not save your progress.', cause: e, stackTrace: st));
    }
  }

  @override
  Future<Result<bool>> hasBadge(String moduleId, String badgeId) async {
    try {
      final rows = await _badgeDao.findByModule(moduleId);
      return Success(rows.any((row) => row.badgeId == badgeId));
    } catch (e, st) {
      AppLogger.error('hasBadge failed for "$moduleId"', error: e, stackTrace: st);
      return Failure(DatabaseFailure('Could not load your badges.', cause: e, stackTrace: st));
    }
  }

  @override
  Future<Result<void>> awardBadge(String moduleId, BadgeInfo badge) async {
    try {
      await _badgeDao.insertBadge(
        BadgeEntity(
          badgeId: badge.id,
          moduleId: moduleId,
          earnedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );
      return const Success(null);
    } catch (e, st) {
      AppLogger.error('awardBadge failed for "$moduleId"', error: e, stackTrace: st);
      return Failure(DatabaseFailure('Could not save your badge.', cause: e, stackTrace: st));
    }
  }

  @override
  Future<Result<Set<String>>> getAllEarnedBadgeIds() async {
    try {
      final rows = await _badgeDao.findAll();
      return Success(rows.map((row) => row.badgeId).toSet());
    } catch (e, st) {
      AppLogger.error('getAllEarnedBadgeIds failed', error: e, stackTrace: st);
      return Failure(DatabaseFailure('Could not load your stickers.', cause: e, stackTrace: st));
    }
  }

  @override
  Future<Result<void>> saveQuizResult({
    required String moduleId,
    required String quizId,
    required int correctCount,
    required int totalCount,
  }) async {
    try {
      await _quizResultDao.insertResult(
        QuizResultEntity(
          moduleId: moduleId,
          quizId: quizId,
          correctCount: correctCount,
          totalCount: totalCount,
          attemptedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );
      return const Success(null);
    } catch (e, st) {
      AppLogger.error('saveQuizResult failed for "$moduleId"/"$quizId"', error: e, stackTrace: st);
      return Failure(DatabaseFailure('Could not save your quiz result.', cause: e, stackTrace: st));
    }
  }
}
