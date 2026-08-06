import 'package:bipod_bondhu/core/error/result.dart';
import 'package:bipod_bondhu/domain/entities/daily_completion.dart';
import 'package:bipod_bondhu/domain/entities/streak_state.dart';
import 'package:bipod_bondhu/domain/repositories/daily_progress_repository.dart';

/// In-memory [DailyProgressRepository] test double.
class FakeDailyProgressRepository implements DailyProgressRepository {
  final Map<String, DailyCompletion> completionsByDate = {};
  StreakState streakState = const StreakState.initial();

  /// Number of times [saveStreakState] was actually invoked — used to
  /// assert idempotent calls don't re-persist.
  int saveStreakStateCallCount = 0;

  @override
  Future<Result<DailyCompletion?>> getCompletion(String dateKey) async => Success(completionsByDate[dateKey]);

  @override
  Future<Result<void>> saveCompletion({
    required String dateKey,
    required String challengeId,
    required bool wasCorrect,
  }) async {
    completionsByDate[dateKey] = DailyCompletion(
      dateKey: dateKey,
      challengeId: challengeId,
      wasCorrect: wasCorrect,
      completedAt: DateTime(2000),
    );
    return const Success(null);
  }

  @override
  Future<Result<List<DailyCompletion>>> getRecentCompletions(int limit) async {
    final sorted = completionsByDate.values.toList()..sort((a, b) => b.dateKey.compareTo(a.dateKey));
    return Success(sorted.take(limit).toList());
  }

  @override
  Future<Result<StreakState>> getStreakState() async => Success(streakState);

  @override
  Future<Result<void>> saveStreakState(StreakState state) async {
    saveStreakStateCallCount++;
    streakState = state;
    return const Success(null);
  }
}
