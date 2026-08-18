// Phase E1: the daily challenge page must render today's challenge via the
// existing QuizRunner, and completing it must show the celebration + a
// "come back tomorrow" natural stop rather than serving more content.
// Opening it a second time on the same day must show the encouraging
// recap instead of the challenge again.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bipod_bondhu/core/constants/app_constants.dart';
import 'package:bipod_bondhu/core/localization/app_translations.dart';
import 'package:bipod_bondhu/core/services/narration_service.dart';
import 'package:bipod_bondhu/core/services/sound_service.dart';
import 'package:bipod_bondhu/core/services/user_pref_service.dart';
import 'package:bipod_bondhu/core/theme/app_durations.dart';
import 'package:bipod_bondhu/domain/entities/daily_challenge.dart';
import 'package:bipod_bondhu/domain/entities/daily_completion.dart';
import 'package:bipod_bondhu/domain/entities/localized_text.dart';
import 'package:bipod_bondhu/domain/entities/quiz_option.dart';
import 'package:bipod_bondhu/domain/entities/quiz_question.dart';
import 'package:bipod_bondhu/domain/entities/streak_state.dart';
import 'package:bipod_bondhu/domain/usecases/award_badge.dart';
import 'package:bipod_bondhu/domain/usecases/get_module_progress.dart';
import 'package:bipod_bondhu/domain/usecases/get_modules.dart';
import 'package:bipod_bondhu/domain/usecases/get_todays_challenge.dart';
import 'package:bipod_bondhu/domain/usecases/mark_challenge_complete.dart';
import 'package:bipod_bondhu/presentation/daily_challenge/daily_challenge_controller.dart';
import 'package:bipod_bondhu/presentation/daily_challenge/daily_challenge_page.dart';

import '../../fakes/fake_content_repository.dart';
import '../../fakes/fake_flutter_tts.dart';
import '../../fakes/fake_daily_challenge_repository.dart';
import '../../fakes/fake_daily_progress_repository.dart';
import '../../fakes/fake_progress_repository.dart';

LocalizedText _text(String value) => LocalizedText(bn: value, en: value);

DailyChallenge _quizChallenge() => DailyChallenge(
      id: 'dc_1',
      type: DailyChallengeType.quiz,
      relatedHazardId: AppConstants.hazardEarthquake,
      difficulty: 1,
      payload: QuizChallengePayload(
        QuizQuestion(
          id: 'dc_1_q',
          prompt: _text('What should you do?'),
          options: [
            QuizOption(id: 'a', label: _text('Wrong'), isCorrect: false),
            QuizOption(id: 'b', label: _text('Right'), isCorrect: true),
          ],
        ),
      ),
    );

DateTime _fixedClock() => DateTime(2026, 8, 3);

DailyChallengeController _buildController({FakeDailyProgressRepository? dailyProgressRepository}) {
  final contentRepository = FakeContentRepository(const []);
  final progressRepository = FakeProgressRepository();
  final dailyProgress = dailyProgressRepository ?? FakeDailyProgressRepository();
  final dailyChallengeRepository = FakeDailyChallengeRepository([_quizChallenge()]);

  return DailyChallengeController(
    getTodaysChallenge: GetTodaysChallenge(
      dailyChallengeRepository: dailyChallengeRepository,
      dailyProgressRepository: dailyProgress,
      getModules: GetModules(contentRepository),
      getModuleProgress: GetModuleProgress(contentRepository: contentRepository, progressRepository: progressRepository),
      clock: _fixedClock,
    ),
    markChallengeComplete: MarkChallengeComplete(
      dailyProgressRepository: dailyProgress,
      progressRepository: progressRepository,
      awardBadge: AwardBadge(progressRepository),
      clock: _fixedClock,
    ),
    narrationService: NarrationService(tts: FakeFlutterTts()),
    soundService: SoundService(),
  );
}

Widget _wrap(DailyChallengeController controller) {
  Get.put<DailyChallengeController>(controller);
  return ScreenUtilInit(
    designSize: AppConstants.designSize,
    minTextAdapt: true,
    splitScreenMode: true,
    builder: (context, child) => GetMaterialApp(
      translations: AppTranslations(),
      locale: const Locale('en', 'US'),
      builder: (context, widget) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: widget!,
      ),
      home: const DailyChallengePage(),
    ),
  );
}

void _useSurfaceSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  setUpAll(() async {
    // NarrationService reads UserPrefService (sound/speed settings) on
    // every speak() call — real app startup does this in main(), so tests
    // that exercise the real service (rather than a stub callback) need
    // the same setup.
    SharedPreferences.setMockInitialValues({});
    await UserPrefService.instance.init();
  });

  tearDown(Get.reset);

  testWidgets('renders today\'s challenge via the existing quiz runner with zero overflow', (tester) async {
    _useSurfaceSize(tester, const Size(340, 720));

    await tester.pumpWidget(_wrap(_buildController()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('What should you do?'), findsOneWidget);
    expect(find.text('Right'), findsOneWidget);
  });

  testWidgets('completing the challenge shows the celebration and a come-back-tomorrow stop', (tester) async {
    await tester.pumpWidget(_wrap(_buildController()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Right'));
    // QuizRunner waits AppDurations.slow before advancing/finishing — mirror
    // the exact pump pattern quiz_runner_test.dart uses for this delay.
    await tester.pump(AppDurations.slow + const Duration(milliseconds: 50));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Well done!'), findsOneWidget);
    expect(find.text('Come back tomorrow for a brand-new challenge!'), findsOneWidget);
  });

  testWidgets(
    'Phase E2: reaching a streak milestone shows the visit-Den invite with zero overflow',
    (tester) async {
      _useSurfaceSize(tester, const Size(340, 720));

      final dailyProgress = FakeDailyProgressRepository()
        ..streakState = const StreakState(
          currentStreak: 2,
          bestStreak: 2,
          freezesAvailable: 2,
          lastCompletedDateKey: '2026-08-02',
        );

      await tester.pumpWidget(_wrap(_buildController(dailyProgressRepository: dailyProgress)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Right'));
      await tester.pump(AppDurations.slow + const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Well done!'), findsOneWidget);
      expect(find.text('Tuku\'s Den'), findsOneWidget);
    },
  );

  testWidgets('reopening an already-completed day shows the recap, not the challenge again', (tester) async {
    final dailyProgress = FakeDailyProgressRepository()
      ..completionsByDate['2026-08-03'] = DailyCompletion(
        dateKey: '2026-08-03',
        challengeId: 'dc_1',
        wasCorrect: true,
        completedAt: DateTime(2026, 8, 3),
      );

    await tester.pumpWidget(_wrap(_buildController(dailyProgressRepository: dailyProgress)));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Done for today!'), findsOneWidget);
    expect(find.text('What should you do?'), findsNothing);
  });
}
