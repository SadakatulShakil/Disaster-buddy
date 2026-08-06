import 'package:equatable/equatable.dart';

import '../../core/error/failures.dart';
import '../../core/error/result.dart';
import '../../core/utils/local_day.dart';
import '../entities/daily_challenge.dart';
import '../entities/daily_completion.dart';
import '../entities/hazard_module.dart';
import '../entities/module_progress.dart';
import '../entities/streak_state.dart';
import '../repositories/daily_challenge_repository.dart';
import '../repositories/daily_progress_repository.dart';
import '../services/daily_challenge_selector.dart';
import '../services/streak_calculator.dart';
import 'get_module_progress.dart';
import 'get_modules.dart';

/// Everything the daily-challenge entry point needs in one load: which
/// challenge is "today's", whether it's already been played, and the
/// caught-up streak state (for the header chip / recap).
final class TodaysChallengeResult extends Equatable {
  const TodaysChallengeResult({
    required this.challenge,
    required this.alreadyCompletedToday,
    required this.streakState,
  });

  final DailyChallenge challenge;
  final bool alreadyCompletedToday;
  final StreakState streakState;

  @override
  List<Object?> get props => [challenge, alreadyCompletedToday, streakState];
}

/// Picks today's daily challenge and reports today's completion + streak
/// status in one call. Reuses [GetModules]/[GetModuleProgress] (rather than
/// duplicating "is this hazard completed" logic) to bias selection toward
/// hazards the child has already finished — a lightweight spaced-repetition
/// nudge — and gracefully falls back to the full pool otherwise.
///
/// Also catches the persisted streak up to [_clock]'s "today" and persists
/// that catch-up immediately (idempotent — see [StreakCalculator.evaluate])
/// so a freeze consumed by an elapsed gap, or a gentle reset, is reflected
/// the moment the child opens the app, not only the next time they play.
final class GetTodaysChallenge {
  const GetTodaysChallenge({
    required DailyChallengeRepository dailyChallengeRepository,
    required DailyProgressRepository dailyProgressRepository,
    required GetModules getModules,
    required GetModuleProgress getModuleProgress,
    DateTime Function() clock = DateTime.now,
  })  : _dailyChallengeRepository = dailyChallengeRepository,
        _dailyProgressRepository = dailyProgressRepository,
        _getModules = getModules,
        _getModuleProgress = getModuleProgress,
        _clock = clock;

  final DailyChallengeRepository _dailyChallengeRepository;
  final DailyProgressRepository _dailyProgressRepository;
  final GetModules _getModules;
  final GetModuleProgress _getModuleProgress;
  final DateTime Function() _clock;

  /// How many recently-played challenges to avoid repeating, where possible.
  static const int _recentAvoidanceWindow = 7;

  Future<Result<TodaysChallengeResult>> call() async {
    final today = _clock();

    final poolResult = await _dailyChallengeRepository.getChallenges();
    if (poolResult case Failure<List<DailyChallenge>>(failure: final failure)) {
      return Failure(failure);
    }
    final pool = (poolResult as Success<List<DailyChallenge>>).value;
    if (pool.isEmpty) {
      return const Failure(ContentParseFailure('No daily challenges are available right now.'));
    }

    final completedHazardIds = await _completedHazardIds();
    final recentIds = await _recentChallengeIds();

    final selected = DailyChallengeSelector.selectFor(
      pool: pool,
      today: today,
      preferredHazardIds: completedHazardIds,
      recentChallengeIds: recentIds,
    );

    final todayKey = LocalDay.keyFor(today);
    final completionResult = await _dailyProgressRepository.getCompletion(todayKey);
    final alreadyDone = completionResult is Success<DailyCompletion?> && completionResult.value != null;

    final streakResult = await _dailyProgressRepository.getStreakState();
    final previousStreak = streakResult is Success<StreakState> ? streakResult.value : const StreakState.initial();
    final caughtUp = StreakCalculator.evaluate(previous: previousStreak, today: today);
    if (caughtUp != previousStreak) {
      await _dailyProgressRepository.saveStreakState(caughtUp);
    }

    return Success(
      TodaysChallengeResult(challenge: selected, alreadyCompletedToday: alreadyDone, streakState: caughtUp),
    );
  }

  Future<Set<String>> _completedHazardIds() async {
    final modulesResult = await _getModules();
    if (modulesResult is! Success<List<HazardModule>>) return {};

    final completed = <String>{};
    for (final module in modulesResult.value) {
      final progressResult = await _getModuleProgress(module.id);
      if (progressResult case Success<ModuleProgress>(value: final progress)) {
        if (progress.isCompleted) completed.add(module.id);
      }
    }
    return completed;
  }

  Future<Set<String>> _recentChallengeIds() async {
    final recentResult = await _dailyProgressRepository.getRecentCompletions(_recentAvoidanceWindow);
    if (recentResult is! Success<List<DailyCompletion>>) return {};
    return recentResult.value.map((completion) => completion.challengeId).toSet();
  }
}
