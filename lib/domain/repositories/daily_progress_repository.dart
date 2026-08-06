import '../../core/error/result.dart';
import '../entities/daily_completion.dart';
import '../entities/streak_state.dart';

/// Persists daily-challenge completions and the child's streak state.
abstract interface class DailyProgressRepository {
  /// The completion recorded for local calendar date [dateKey], or null if
  /// that day hasn't been completed.
  Future<Result<DailyCompletion?>> getCompletion(String dateKey);

  Future<Result<void>> saveCompletion({
    required String dateKey,
    required String challengeId,
    required bool wasCorrect,
  });

  /// The most recent completions, newest first, used both to avoid
  /// repeating a recently-played challenge and to render the streak chain.
  Future<Result<List<DailyCompletion>>> getRecentCompletions(int limit);

  /// The persisted streak state, or [StreakState.initial] if the child has
  /// never completed a daily challenge.
  Future<Result<StreakState>> getStreakState();

  Future<Result<void>> saveStreakState(StreakState state);
}
