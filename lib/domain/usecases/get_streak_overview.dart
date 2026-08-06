import 'package:equatable/equatable.dart';

import '../../core/error/result.dart';
import '../entities/daily_completion.dart';
import '../entities/streak_state.dart';
import '../repositories/daily_progress_repository.dart';
import '../services/streak_calculator.dart';

/// Everything [StreakChainView] needs: the caught-up streak counters plus
/// the rendered day-by-day chain for the last [GetStreakOverview.windowDays].
final class StreakOverview extends Equatable {
  const StreakOverview({required this.state, required this.chain});

  final StreakState state;
  final List<DayChainEntry> chain;

  @override
  List<Object?> get props => [state, chain];
}

/// Loads the streak state and enough recent completion history to render a
/// [StreakOverview] via [StreakCalculator.buildChain].
final class GetStreakOverview {
  const GetStreakOverview({
    required DailyProgressRepository dailyProgressRepository,
    DateTime Function() clock = DateTime.now,
    this.windowDays = 28,
  })  : _dailyProgressRepository = dailyProgressRepository,
        _clock = clock;

  final DailyProgressRepository _dailyProgressRepository;
  final DateTime Function() _clock;
  final int windowDays;

  Future<Result<StreakOverview>> call() async {
    final today = _clock();

    final streakResult = await _dailyProgressRepository.getStreakState();
    if (streakResult case Failure<StreakState>(failure: final failure)) {
      return Failure(failure);
    }
    final streak = (streakResult as Success<StreakState>).value;
    final caughtUp = StreakCalculator.evaluate(previous: streak, today: today);

    // Fetch extra lead-in history beyond the display window so a gap that
    // started before the window can still be correctly resolved as
    // covered-by-freeze or not.
    final lookback = windowDays + StreakCalculator.freezeCapacity + 14;
    final completionsResult = await _dailyProgressRepository.getRecentCompletions(lookback);
    final completions =
        completionsResult is Success<List<DailyCompletion>> ? completionsResult.value : const <DailyCompletion>[];
    final completedKeys = completions.map((completion) => completion.dateKey).toSet();

    final chain = StreakCalculator.buildChain(completedDateKeys: completedKeys, today: today, windowDays: windowDays);
    return Success(StreakOverview(state: caughtUp, chain: chain));
  }
}
