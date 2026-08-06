import '../../core/error/failures.dart';
import '../../core/error/result.dart';
import '../../core/utils/app_logger.dart';
import '../../domain/entities/daily_completion.dart';
import '../../domain/entities/streak_state.dart';
import '../../domain/repositories/daily_progress_repository.dart';
import '../local/daos/daily_completion_dao.dart';
import '../local/daos/streak_state_dao.dart';
import '../local/entities/daily_completion_entity.dart';
import '../local/entities/streak_state_entity.dart';

final class DailyProgressRepositoryImpl implements DailyProgressRepository {
  const DailyProgressRepositoryImpl({
    required DailyCompletionDao dailyCompletionDao,
    required StreakStateDao streakStateDao,
  })  : _dailyCompletionDao = dailyCompletionDao,
        _streakStateDao = streakStateDao;

  final DailyCompletionDao _dailyCompletionDao;
  final StreakStateDao _streakStateDao;

  @override
  Future<Result<DailyCompletion?>> getCompletion(String dateKey) async {
    try {
      final row = await _dailyCompletionDao.findByDate(dateKey);
      return Success(row == null ? null : _toDomain(row));
    } catch (e, st) {
      AppLogger.error('getCompletion failed for "$dateKey"', error: e, stackTrace: st);
      return Failure(DatabaseFailure('Could not load today\'s challenge status.', cause: e, stackTrace: st));
    }
  }

  @override
  Future<Result<void>> saveCompletion({
    required String dateKey,
    required String challengeId,
    required bool wasCorrect,
  }) async {
    try {
      await _dailyCompletionDao.insertOrUpdate(
        DailyCompletionEntity(
          dateKey: dateKey,
          challengeId: challengeId,
          wasCorrect: wasCorrect,
          completedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );
      return const Success(null);
    } catch (e, st) {
      AppLogger.error('saveCompletion failed for "$dateKey"', error: e, stackTrace: st);
      return Failure(DatabaseFailure('Could not save today\'s challenge.', cause: e, stackTrace: st));
    }
  }

  @override
  Future<Result<List<DailyCompletion>>> getRecentCompletions(int limit) async {
    try {
      final rows = await _dailyCompletionDao.findRecent(limit);
      return Success([for (final row in rows) _toDomain(row)]);
    } catch (e, st) {
      AppLogger.error('getRecentCompletions failed', error: e, stackTrace: st);
      return Failure(DatabaseFailure('Could not load your recent challenges.', cause: e, stackTrace: st));
    }
  }

  @override
  Future<Result<StreakState>> getStreakState() async {
    try {
      final row = await _streakStateDao.find();
      if (row == null) return const Success(StreakState.initial());
      return Success(
        StreakState(
          currentStreak: row.currentStreak,
          bestStreak: row.bestStreak,
          freezesAvailable: row.freezesAvailable,
          lastCompletedDateKey: row.lastCompletedDateKey,
        ),
      );
    } catch (e, st) {
      AppLogger.error('getStreakState failed', error: e, stackTrace: st);
      return Failure(DatabaseFailure('Could not load your streak.', cause: e, stackTrace: st));
    }
  }

  @override
  Future<Result<void>> saveStreakState(StreakState state) async {
    try {
      await _streakStateDao.save(
        StreakStateEntity(
          currentStreak: state.currentStreak,
          bestStreak: state.bestStreak,
          freezesAvailable: state.freezesAvailable,
          lastCompletedDateKey: state.lastCompletedDateKey,
        ),
      );
      return const Success(null);
    } catch (e, st) {
      AppLogger.error('saveStreakState failed', error: e, stackTrace: st);
      return Failure(DatabaseFailure('Could not save your streak.', cause: e, stackTrace: st));
    }
  }

  DailyCompletion _toDomain(DailyCompletionEntity row) => DailyCompletion(
        dateKey: row.dateKey,
        challengeId: row.challengeId,
        wasCorrect: row.wasCorrect,
        completedAt: DateTime.fromMillisecondsSinceEpoch(row.completedAt),
      );
}
