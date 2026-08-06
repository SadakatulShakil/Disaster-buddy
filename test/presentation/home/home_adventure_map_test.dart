// Phase 2: the Adventure Map must show all 3 hazard modules as stops and
// derive each stop's available/completed/locked state purely from real
// progress — module 2 stays locked until module 1 is completed.
//
// Phase E1: the header also carries a "Tuku's Daily Challenge" card driven
// by GetTodaysChallenge — every test constructs one via fakes so the card
// has real (if minimal) data to render.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:bipod_bondhu/core/constants/app_constants.dart';
import 'package:bipod_bondhu/core/localization/app_translations.dart';
import 'package:bipod_bondhu/domain/entities/badge_info.dart';
import 'package:bipod_bondhu/domain/entities/beat.dart';
import 'package:bipod_bondhu/domain/entities/daily_challenge.dart';
import 'package:bipod_bondhu/domain/entities/daily_completion.dart';
import 'package:bipod_bondhu/domain/entities/hazard_module.dart';
import 'package:bipod_bondhu/domain/entities/localized_text.dart';
import 'package:bipod_bondhu/domain/entities/quiz_option.dart';
import 'package:bipod_bondhu/domain/entities/quiz_question.dart';
import 'package:bipod_bondhu/domain/usecases/get_activities.dart';
import 'package:bipod_bondhu/domain/usecases/get_den_state.dart';
import 'package:bipod_bondhu/domain/usecases/get_earned_collection.dart';
import 'package:bipod_bondhu/domain/usecases/get_module_progress.dart';
import 'package:bipod_bondhu/domain/usecases/get_modules.dart';
import 'package:bipod_bondhu/domain/usecases/get_todays_challenge.dart';
import 'package:bipod_bondhu/presentation/home/home_controller.dart';
import 'package:bipod_bondhu/presentation/home/home_page.dart';
import 'package:bipod_bondhu/presentation/home/widgets/module_stop.dart';

import '../../fakes/fake_activity_repository.dart';
import '../../fakes/fake_content_repository.dart';
import '../../fakes/fake_daily_challenge_repository.dart';
import '../../fakes/fake_daily_progress_repository.dart';
import '../../fakes/fake_den_repository.dart';
import '../../fakes/fake_progress_repository.dart';

LocalizedText _text(String value) => LocalizedText(bn: value, en: value);

HazardModule _module(String id, int order) => HazardModule(
      id: id,
      order: order,
      title: _text(id),
      themeColorHex: '#0E7C86',
      iconAsset: 'icon.png',
      safeAction: _text('safe'),
      badge: BadgeInfo(id: '${id}_badge', title: _text('badge'), iconAsset: 'badge.png'),
      beats: [StoryBeat(id: '${id}_beat', order: 1, slides: const [])],
    );

DailyChallenge _dailyChallenge() => DailyChallenge(
      id: 'dc_1',
      type: DailyChallengeType.quiz,
      relatedHazardId: AppConstants.hazardEarthquake,
      difficulty: 1,
      payload: QuizChallengePayload(
        QuizQuestion(
          id: 'dc_1_q',
          prompt: _text('prompt'),
          options: [
            QuizOption(id: 'a', label: _text('a'), isCorrect: true),
            QuizOption(id: 'b', label: _text('b'), isCorrect: false),
          ],
        ),
      ),
    );

GetTodaysChallenge _getTodaysChallenge({
  required FakeContentRepository contentRepository,
  required FakeProgressRepository progressRepository,
  FakeDailyProgressRepository? dailyProgressRepository,
  DateTime Function() clock = DateTime.now,
}) {
  return GetTodaysChallenge(
    dailyChallengeRepository: FakeDailyChallengeRepository([_dailyChallenge()]),
    dailyProgressRepository: dailyProgressRepository ?? FakeDailyProgressRepository(),
    getModules: GetModules(contentRepository),
    getModuleProgress: GetModuleProgress(contentRepository: contentRepository, progressRepository: progressRepository),
    clock: clock,
  );
}

Widget _wrap(HomeController controller) {
  Get.put<HomeController>(controller);
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
      home: const HomePage(),
    ),
  );
}

/// Sets the test surface to a fixed logical [size], resetting it once the
/// test finishes.
void _useSurfaceSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  tearDown(Get.reset);

  testWidgets('shows 3 stops with completed/available/locked reflecting real progress', (tester) async {
    final modules = [
      _module(AppConstants.hazardEarthquake, 1),
      _module(AppConstants.hazardFlood, 2),
      _module(AppConstants.hazardLightning, 3),
    ];
    final contentRepository = FakeContentRepository(modules);
    final progressRepository = FakeProgressRepository()
      ..completedBeatIdsByModule[AppConstants.hazardEarthquake] = {'${AppConstants.hazardEarthquake}_beat'};

    final controller = HomeController(
      getModules: GetModules(contentRepository),
      getModuleProgress: GetModuleProgress(
        contentRepository: contentRepository,
        progressRepository: progressRepository,
      ),
      getTodaysChallenge: _getTodaysChallenge(contentRepository: contentRepository, progressRepository: progressRepository),
      getDenState: GetDenState(FakeDenRepository()),
      getEarnedCollection: GetEarnedCollection(
        getModules: GetModules(contentRepository),
        getActivities: GetActivities(FakeActivityRepository(const [])),
        progressRepository: progressRepository,
      ),
    );

    await tester.pumpWidget(_wrap(controller));
    await tester.pumpAndSettle();

    expect(find.byType(ModuleStop), findsNWidgets(3));

    // Module 0 (earthquake) is completed.
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.text('Completed!'), findsOneWidget);

    // Module 1 (flood) unlocked because module 0 is completed -> available,
    // no lock badge for it.
    // Module 2 (lightning) stays locked until module 1 completes.
    expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
    expect(find.text('Coming next!'), findsOneWidget);
  });

  testWidgets('renders all 4 stops with zero overflow on a narrow phone width', (tester) async {
    _useSurfaceSize(tester, const Size(340, 720));

    final modules = [
      _module(AppConstants.hazardEarthquake, 1),
      _module(AppConstants.hazardFlood, 2),
      _module(AppConstants.hazardLightning, 3),
      _module(AppConstants.hazardFirstAid, 4),
    ];
    final contentRepository = FakeContentRepository(modules);
    final progressRepository = FakeProgressRepository();
    final controller = HomeController(
      getModules: GetModules(contentRepository),
      getModuleProgress: GetModuleProgress(
        contentRepository: contentRepository,
        progressRepository: progressRepository,
      ),
      getTodaysChallenge: _getTodaysChallenge(contentRepository: contentRepository, progressRepository: progressRepository),
      getDenState: GetDenState(FakeDenRepository()),
      getEarnedCollection: GetEarnedCollection(
        getModules: GetModules(contentRepository),
        getActivities: GetActivities(FakeActivityRepository(const [])),
        progressRepository: progressRepository,
      ),
    );

    await tester.pumpWidget(_wrap(controller));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(ModuleStop), findsNWidgets(4));
    expect(find.text('activities'.tr), findsOneWidget);
  });

  testWidgets('renders all 4 stops with zero overflow on a tablet-portrait width', (tester) async {
    _useSurfaceSize(tester, const Size(800, 1280));

    final modules = [
      _module(AppConstants.hazardEarthquake, 1),
      _module(AppConstants.hazardFlood, 2),
      _module(AppConstants.hazardLightning, 3),
      _module(AppConstants.hazardFirstAid, 4),
    ];
    final contentRepository = FakeContentRepository(modules);
    final progressRepository = FakeProgressRepository();
    final controller = HomeController(
      getModules: GetModules(contentRepository),
      getModuleProgress: GetModuleProgress(
        contentRepository: contentRepository,
        progressRepository: progressRepository,
      ),
      getTodaysChallenge: _getTodaysChallenge(contentRepository: contentRepository, progressRepository: progressRepository),
      getDenState: GetDenState(FakeDenRepository()),
      getEarnedCollection: GetEarnedCollection(
        getModules: GetModules(contentRepository),
        getActivities: GetActivities(FakeActivityRepository(const [])),
        progressRepository: progressRepository,
      ),
    );

    await tester.pumpWidget(_wrap(controller));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(ModuleStop), findsNWidgets(4));
  });

  testWidgets('shows the daily challenge card as "new" when today is undone', (tester) async {
    final modules = [_module(AppConstants.hazardEarthquake, 1)];
    final contentRepository = FakeContentRepository(modules);
    final progressRepository = FakeProgressRepository();
    final controller = HomeController(
      getModules: GetModules(contentRepository),
      getModuleProgress: GetModuleProgress(
        contentRepository: contentRepository,
        progressRepository: progressRepository,
      ),
      getTodaysChallenge: _getTodaysChallenge(contentRepository: contentRepository, progressRepository: progressRepository),
      getDenState: GetDenState(FakeDenRepository()),
      getEarnedCollection: GetEarnedCollection(
        getModules: GetModules(contentRepository),
        getActivities: GetActivities(FakeActivityRepository(const [])),
        progressRepository: progressRepository,
      ),
    );

    await tester.pumpWidget(_wrap(controller));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text("Tuku's Daily Challenge"), findsOneWidget);
    expect(find.text("Play today's new challenge!"), findsOneWidget);
  });

  testWidgets('shows the daily challenge card as done when today is already completed', (tester) async {
    final modules = [_module(AppConstants.hazardEarthquake, 1)];
    final contentRepository = FakeContentRepository(modules);
    final progressRepository = FakeProgressRepository();
    final fixedToday = DateTime(2026, 8, 3);
    final dailyProgressRepository = FakeDailyProgressRepository()
      ..completionsByDate['2026-08-03'] = DailyCompletion(
        dateKey: '2026-08-03',
        challengeId: 'dc_1',
        wasCorrect: true,
        completedAt: fixedToday,
      );
    final controller = HomeController(
      getModules: GetModules(contentRepository),
      getModuleProgress: GetModuleProgress(
        contentRepository: contentRepository,
        progressRepository: progressRepository,
      ),
      getTodaysChallenge: _getTodaysChallenge(
        contentRepository: contentRepository,
        progressRepository: progressRepository,
        dailyProgressRepository: dailyProgressRepository,
        clock: () => fixedToday,
      ),
      getDenState: GetDenState(FakeDenRepository()),
      getEarnedCollection: GetEarnedCollection(
        getModules: GetModules(contentRepository),
        getActivities: GetActivities(FakeActivityRepository(const [])),
        progressRepository: progressRepository,
      ),
    );

    await tester.pumpWidget(_wrap(controller));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('All done for today! Come back tomorrow.'), findsOneWidget);
  });
}
