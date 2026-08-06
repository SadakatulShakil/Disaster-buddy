import '../../core/error/result.dart';
import '../../core/utils/local_day.dart';
import '../entities/daily_completion.dart';
import '../entities/streak_state.dart';
import '../repositories/daily_progress_repository.dart';
import '../repositories/progress_repository.dart';
import '../services/streak_calculator.dart';
import '../services/streak_milestones.dart';
import 'award_badge.dart';

/// Records today's daily-challenge completion and advances the "chain with
/// grace" streak, awarding a one-time streak sticker via the existing
/// badge/[AwardBadge] system on reaching a milestone length.
///
/// Idempotent: completing the same local day twice (dateKey, challengeId,
/// wasCorrect) never double-counts the streak or re-awards a badge — the
/// second call simply returns the already-caught-up state.
final class MarkChallengeComplete {
  const MarkChallengeComplete({
    required DailyProgressRepository dailyProgressRepository,
    required ProgressRepository progressRepository,
    required AwardBadge awardBadge,
    DateTime Function() clock = DateTime.now,
  })  : _dailyProgressRepository = dailyProgressRepository,
        _progressRepository = progressRepository,
        _awardBadge = awardBadge,
        _clock = clock;

  final DailyProgressRepository _dailyProgressRepository;
  final ProgressRepository _progressRepository;
  final AwardBadge _awardBadge;
  final DateTime Function() _clock;

  Future<Result<StreakUpdate>> call({required String challengeId, required bool wasCorrect}) async {
    final today = _clock();
    final todayKey = LocalDay.keyFor(today);

    final existingResult = await _dailyProgressRepository.getCompletion(todayKey);
    if (existingResult case Failure<DailyCompletion?>(failure: final failure)) {
      return Failure(failure);
    }
    final alreadyCompletedToday = (existingResult as Success<DailyCompletion?>).value != null;

    final streakResult = await _dailyProgressRepository.getStreakState();
    if (streakResult case Failure<StreakState>(failure: final failure)) {
      return Failure(failure);
    }
    final previousStreak = (streakResult as Success<StreakState>).value;

    if (alreadyCompletedToday) {
      final caughtUp = StreakCalculator.evaluate(previous: previousStreak, today: today);
      return Success(StreakUpdate(state: caughtUp, newMilestone: null));
    }

    final saveCompletionResult = await _dailyProgressRepository.saveCompletion(
      dateKey: todayKey,
      challengeId: challengeId,
      wasCorrect: wasCorrect,
    );
    if (saveCompletionResult case Failure<void>(failure: final failure)) {
      return Failure(failure);
    }

    final update = StreakCalculator.recordCompletion(previous: previousStreak, today: today);

    final saveStreakResult = await _dailyProgressRepository.saveStreakState(update.state);
    if (saveStreakResult case Failure<void>(failure: final failure)) {
      return Failure(failure);
    }

    await _awardMilestoneBadgeIfNeeded(update.newMilestone);

    return Success(update);
  }

  Future<void> _awardMilestoneBadgeIfNeeded(int? milestone) async {
    if (milestone == null) return;
    final badge = StreakMilestones.badgeFor(milestone);
    if (badge == null) return;

    final hasBadgeResult = await _progressRepository.hasBadge(StreakMilestones.ownerId, badge.id);
    final alreadyEarned = hasBadgeResult is Success<bool> && hasBadgeResult.value;
    if (alreadyEarned) return;

    await _awardBadge(moduleId: StreakMilestones.ownerId, badge: badge);
  }
}
