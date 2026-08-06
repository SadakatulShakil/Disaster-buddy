// Phase 1/2 verification: HomePage (the Adventure Map) renders real module
// titles and completion state from HomeController, proving the content
// chain (JSON -> source -> repo -> usecase -> controller -> UI) still works
// end to end after the Phase 2 UI rewrite.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:bipod_bondhu/core/constants/app_constants.dart';
import 'package:bipod_bondhu/core/localization/app_translations.dart';
import 'package:bipod_bondhu/domain/entities/badge_info.dart';
import 'package:bipod_bondhu/domain/entities/beat.dart';
import 'package:bipod_bondhu/domain/entities/daily_challenge.dart';
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

import 'fakes/fake_activity_repository.dart';
import 'fakes/fake_content_repository.dart';
import 'fakes/fake_daily_challenge_repository.dart';
import 'fakes/fake_daily_progress_repository.dart';
import 'fakes/fake_den_repository.dart';
import 'fakes/fake_progress_repository.dart';

const _title = LocalizedText(bn: 'ভূমিকম্প', en: 'Earthquake');

HazardModule _module() => const HazardModule(
      id: 'earthquake',
      order: 1,
      title: _title,
      themeColorHex: '#A0522D',
      iconAsset: 'icon.png',
      safeAction: _title,
      badge: BadgeInfo(id: 'earthquake_badge', title: _title, iconAsset: 'badge.png'),
      beats: [StoryBeat(id: 'beat_1', order: 1, slides: [])],
    );

GetTodaysChallenge _getTodaysChallenge(FakeContentRepository contentRepository, FakeProgressRepository progressRepository) {
  return GetTodaysChallenge(
    dailyChallengeRepository: FakeDailyChallengeRepository([
      const DailyChallenge(
        id: 'dc_1',
        type: DailyChallengeType.quiz,
        relatedHazardId: 'earthquake',
        difficulty: 1,
        payload: QuizChallengePayload(
          QuizQuestion(
            id: 'dc_1_q',
            prompt: _title,
            options: [
              QuizOption(id: 'a', label: _title, isCorrect: true),
              QuizOption(id: 'b', label: _title, isCorrect: false),
            ],
          ),
        ),
      ),
    ]),
    dailyProgressRepository: FakeDailyProgressRepository(),
    getModules: GetModules(contentRepository),
    getModuleProgress: GetModuleProgress(contentRepository: contentRepository, progressRepository: progressRepository),
  );
}

Widget _wrap(HomeController controller) {
  Get.put<HomeController>(controller);
  return ScreenUtilInit(
    designSize: AppConstants.designSize,
    builder: (context, child) => GetMaterialApp(
      translations: AppTranslations(),
      locale: const Locale('en', 'US'),
      // Reduce-motion so entrance/pulse animations don't keep ticking and
      // block pumpAndSettle.
      builder: (context, widget) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: widget!,
      ),
      home: const HomePage(),
    ),
  );
}

void main() {
  tearDown(Get.reset);

  testWidgets('shows the module title once loaded', (tester) async {
    final contentRepository = FakeContentRepository([_module()]);
    final progressRepository = FakeProgressRepository();
    final controller = HomeController(
      getModules: GetModules(contentRepository),
      getModuleProgress: GetModuleProgress(
        contentRepository: contentRepository,
        progressRepository: progressRepository,
      ),
      getTodaysChallenge: _getTodaysChallenge(contentRepository, progressRepository),
      getDenState: GetDenState(FakeDenRepository()),
      getEarnedCollection: GetEarnedCollection(
        getModules: GetModules(contentRepository),
        getActivities: GetActivities(FakeActivityRepository(const [])),
        progressRepository: progressRepository,
      ),
    );

    await tester.pumpWidget(_wrap(controller));
    await tester.pumpAndSettle();

    expect(find.text('Earthquake'), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsNothing);
  });

  testWidgets('shows a checkmark once the module is completed', (tester) async {
    final contentRepository = FakeContentRepository([_module()]);
    final progressRepository = FakeProgressRepository()
      ..completedBeatIdsByModule['earthquake'] = {'beat_1'};
    final controller = HomeController(
      getModules: GetModules(contentRepository),
      getModuleProgress: GetModuleProgress(
        contentRepository: contentRepository,
        progressRepository: progressRepository,
      ),
      getTodaysChallenge: _getTodaysChallenge(contentRepository, progressRepository),
      getDenState: GetDenState(FakeDenRepository()),
      getEarnedCollection: GetEarnedCollection(
        getModules: GetModules(contentRepository),
        getActivities: GetActivities(FakeActivityRepository(const [])),
        progressRepository: progressRepository,
      ),
    );

    await tester.pumpWidget(_wrap(controller));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
  });
}
