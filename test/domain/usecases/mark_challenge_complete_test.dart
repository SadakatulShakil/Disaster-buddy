// Phase E1: MarkChallengeComplete must be idempotent (completing the same
// local day twice never double-counts the streak or re-awards a badge)
// and must award a one-time streak sticker on reaching a milestone length.

import 'package:flutter_test/flutter_test.dart';

import 'package:bipod_bondhu/core/error/result.dart';
import 'package:bipod_bondhu/domain/entities/streak_state.dart';
import 'package:bipod_bondhu/domain/services/streak_calculator.dart';
import 'package:bipod_bondhu/domain/services/streak_milestones.dart';
import 'package:bipod_bondhu/domain/usecases/award_badge.dart';
import 'package:bipod_bondhu/domain/usecases/mark_challenge_complete.dart';

import '../../fakes/fake_daily_progress_repository.dart';
import '../../fakes/fake_progress_repository.dart';

void main() {
  late FakeDailyProgressRepository dailyProgressRepository;
  late FakeProgressRepository progressRepository;
  late MarkChallengeComplete useCase;

  setUp(() {
    dailyProgressRepository = FakeDailyProgressRepository();
    progressRepository = FakeProgressRepository();
    useCase = MarkChallengeComplete(
      dailyProgressRepository: dailyProgressRepository,
      progressRepository: progressRepository,
      awardBadge: AwardBadge(progressRepository),
      clock: () => DateTime(2026, 8, 3),
    );
  });

  test('first completion of the day starts a streak of 1', () async {
    final result = await useCase(challengeId: 'c1', wasCorrect: true);

    expect(result, isA<Success<StreakUpdate>>());
    final update = (result as Success<StreakUpdate>).value;
    expect(update.state.currentStreak, 1);
    expect(dailyProgressRepository.completionsByDate['2026-08-03']?.challengeId, 'c1');
  });

  test('completing the same day twice is idempotent', () async {
    final first = (await useCase(challengeId: 'c1', wasCorrect: true) as Success<StreakUpdate>).value;
    final second = (await useCase(challengeId: 'c1', wasCorrect: true) as Success<StreakUpdate>).value;

    expect(second.state, first.state);
    expect(dailyProgressRepository.saveStreakStateCallCount, 1);
  });

  test('completing the same day twice never double-counts the streak', () async {
    await useCase(challengeId: 'c1', wasCorrect: true);
    final result = await useCase(challengeId: 'c1', wasCorrect: true);

    final update = (result as Success<StreakUpdate>).value;
    expect(update.state.currentStreak, 1);
  });

  test('reaching a milestone streak length awards the matching sticker exactly once', () async {
    dailyProgressRepository.streakState = const StreakState(
      currentStreak: 2,
      bestStreak: 2,
      freezesAvailable: 2,
      lastCompletedDateKey: '2026-08-02',
    );

    final result = await useCase(challengeId: 'c1', wasCorrect: true);

    final update = (result as Success<StreakUpdate>).value;
    expect(update.newMilestone, 3);
    expect(progressRepository.awardBadgeCallCount, 1);
    expect(progressRepository.earnedBadgeIds, contains(StreakMilestones.badgeFor(3)!.id));
  });

  test('does not re-award an already-earned milestone badge', () async {
    final badge = StreakMilestones.badgeFor(3)!;
    progressRepository.earnedBadgeIds.add(badge.id);
    dailyProgressRepository.streakState = const StreakState(
      currentStreak: 2,
      bestStreak: 2,
      freezesAvailable: 2,
      lastCompletedDateKey: '2026-08-02',
    );

    await useCase(challengeId: 'c1', wasCorrect: true);

    expect(progressRepository.awardBadgeCallCount, 0);
  });

  test('a wrong answer still completes the day and advances the streak', () async {
    final result = await useCase(challengeId: 'c1', wasCorrect: false);

    final update = (result as Success<StreakUpdate>).value;
    expect(update.state.currentStreak, 1);
    expect(dailyProgressRepository.completionsByDate['2026-08-03']?.wasCorrect, isFalse);
  });
}
