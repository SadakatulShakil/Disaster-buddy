// Phase E1: GetTodaysChallenge must pick a stable-per-day challenge,
// prefer a completed hazard's content, report whether today is already
// done, and catch the persisted streak up to "today".

import 'package:flutter_test/flutter_test.dart';

import 'package:bipod_bondhu/core/error/result.dart';
import 'package:bipod_bondhu/domain/entities/badge_info.dart';
import 'package:bipod_bondhu/domain/entities/beat.dart';
import 'package:bipod_bondhu/domain/entities/daily_challenge.dart';
import 'package:bipod_bondhu/domain/entities/daily_completion.dart';
import 'package:bipod_bondhu/domain/entities/hazard_module.dart';
import 'package:bipod_bondhu/domain/entities/localized_text.dart';
import 'package:bipod_bondhu/domain/entities/quiz_option.dart';
import 'package:bipod_bondhu/domain/entities/quiz_question.dart';
import 'package:bipod_bondhu/domain/entities/streak_state.dart';
import 'package:bipod_bondhu/domain/usecases/get_module_progress.dart';
import 'package:bipod_bondhu/domain/usecases/get_modules.dart';
import 'package:bipod_bondhu/domain/usecases/get_todays_challenge.dart';

import '../../fakes/fake_content_repository.dart';
import '../../fakes/fake_daily_challenge_repository.dart';
import '../../fakes/fake_daily_progress_repository.dart';
import '../../fakes/fake_progress_repository.dart';

const _text = LocalizedText(bn: 'x', en: 'x');

DailyChallenge _challenge(String id, String hazardId) => DailyChallenge(
      id: id,
      type: DailyChallengeType.quiz,
      relatedHazardId: hazardId,
      difficulty: 1,
      payload: QuizChallengePayload(
        QuizQuestion(
          id: '${id}_q',
          prompt: _text,
          options: const [
            QuizOption(id: 'a', label: _text, isCorrect: true),
            QuizOption(id: 'b', label: _text, isCorrect: false),
          ],
        ),
      ),
    );

HazardModule _module(String id) => HazardModule(
      id: id,
      order: 1,
      title: _text,
      themeColorHex: '#0E7C86',
      iconAsset: 'icon.png',
      safeAction: _text,
      badge: BadgeInfo(id: '${id}_badge', title: _text, iconAsset: 'badge.png'),
      beats: [StoryBeat(id: '${id}_beat', order: 1, slides: const [])],
    );

void main() {
  late FakeDailyChallengeRepository dailyChallengeRepository;
  late FakeDailyProgressRepository dailyProgressRepository;
  late FakeContentRepository contentRepository;
  late FakeProgressRepository progressRepository;

  GetTodaysChallenge buildUseCase({DateTime Function()? clock}) {
    contentRepository = FakeContentRepository([_module('earthquake'), _module('flood')]);
    progressRepository = FakeProgressRepository();
    return GetTodaysChallenge(
      dailyChallengeRepository: dailyChallengeRepository,
      dailyProgressRepository: dailyProgressRepository,
      getModules: GetModules(contentRepository),
      getModuleProgress: GetModuleProgress(contentRepository: contentRepository, progressRepository: progressRepository),
      clock: clock ?? () => DateTime(2026, 8, 3),
    );
  }

  setUp(() {
    dailyChallengeRepository = FakeDailyChallengeRepository([_challenge('c1', 'earthquake'), _challenge('c2', 'flood')]);
    dailyProgressRepository = FakeDailyProgressRepository();
  });

  test('reports alreadyCompletedToday=false when nothing has been done yet', () async {
    final useCase = buildUseCase();

    final result = await useCase();

    expect(result, isA<Success<TodaysChallengeResult>>());
    final data = (result as Success<TodaysChallengeResult>).value;
    expect(data.alreadyCompletedToday, isFalse);
    expect(['c1', 'c2'], contains(data.challenge.id));
  });

  test('reports alreadyCompletedToday=true once today has a saved completion', () async {
    dailyProgressRepository.completionsByDate['2026-08-03'] = DailyCompletion(
      dateKey: '2026-08-03',
      challengeId: 'c1',
      wasCorrect: true,
      completedAt: DateTime(2026, 8, 3),
    );
    final useCase = buildUseCase();

    final result = await useCase();

    final data = (result as Success<TodaysChallengeResult>).value;
    expect(data.alreadyCompletedToday, isTrue);
  });

  test('prefers a challenge tied to an already-completed hazard', () async {
    progressRepository = FakeProgressRepository()
      ..completedBeatIdsByModule['earthquake'] = {'earthquake_beat'};
    contentRepository = FakeContentRepository([_module('earthquake'), _module('flood')]);
    final useCase = GetTodaysChallenge(
      dailyChallengeRepository: dailyChallengeRepository,
      dailyProgressRepository: dailyProgressRepository,
      getModules: GetModules(contentRepository),
      getModuleProgress: GetModuleProgress(contentRepository: contentRepository, progressRepository: progressRepository),
      clock: () => DateTime(2026, 8, 3),
    );

    final result = await useCase();

    final data = (result as Success<TodaysChallengeResult>).value;
    expect(data.challenge.relatedHazardId, 'earthquake');
  });

  test('is stable across repeated calls for the same day', () async {
    final useCase = buildUseCase();

    final first = (await useCase() as Success<TodaysChallengeResult>).value;
    final second = (await useCase() as Success<TodaysChallengeResult>).value;

    expect(first.challenge.id, second.challenge.id);
  });

  test('propagates a failure when the pool is empty', () async {
    dailyChallengeRepository = FakeDailyChallengeRepository(const []);
    final useCase = buildUseCase();

    final result = await useCase();

    expect(result, isA<Failure<TodaysChallengeResult>>());
  });

  test('persists a caught-up streak state when a gap has elapsed', () async {
    dailyProgressRepository.streakState = const StreakState(
      currentStreak: 4,
      bestStreak: 4,
      freezesAvailable: 0,
      lastCompletedDateKey: '2026-08-01',
    );
    final useCase = buildUseCase();

    final result = await useCase();

    final data = (result as Success<TodaysChallengeResult>).value;
    // Gap of 1 missed day (2026-08-02), no freeze available -> gentle reset.
    expect(data.streakState.currentStreak, 0);
    expect(dailyProgressRepository.streakState.currentStreak, 0);
  });
}
