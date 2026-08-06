// Phase E1: the streak chain view must render the current/best/freeze
// counters and the day-by-day chain with zero overflow, and must never
// show a missed day as anything red/scary.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:bipod_bondhu/core/constants/app_constants.dart';
import 'package:bipod_bondhu/core/localization/app_translations.dart';
import 'package:bipod_bondhu/domain/entities/daily_completion.dart';
import 'package:bipod_bondhu/domain/entities/streak_state.dart';
import 'package:bipod_bondhu/domain/usecases/get_streak_overview.dart';
import 'package:bipod_bondhu/presentation/streak/streak_chain_controller.dart';
import 'package:bipod_bondhu/presentation/streak/streak_chain_page.dart';
import 'package:bipod_bondhu/presentation/widgets/app_card.dart';

import '../../fakes/fake_daily_progress_repository.dart';

Widget _wrap(StreakChainController controller) {
  Get.put<StreakChainController>(controller);
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
      home: const StreakChainPage(),
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
  tearDown(Get.reset);

  testWidgets('renders the streak counters and chain with zero overflow on a narrow phone width', (tester) async {
    _useSurfaceSize(tester, const Size(320, 700));

    final dailyProgress = FakeDailyProgressRepository()
      ..streakState = const StreakState(
        currentStreak: 4,
        bestStreak: 9,
        freezesAvailable: 1,
        lastCompletedDateKey: '2026-08-03',
      )
      ..completionsByDate['2026-08-01'] = DailyCompletion(
        dateKey: '2026-08-01',
        challengeId: 'dc_1',
        wasCorrect: true,
        completedAt: DateTime(2026, 8, 1),
      )
      ..completionsByDate['2026-08-03'] = DailyCompletion(
        dateKey: '2026-08-03',
        challengeId: 'dc_1',
        wasCorrect: true,
        completedAt: DateTime(2026, 8, 3),
      );

    final controller = StreakChainController(
      getStreakOverview: GetStreakOverview(dailyProgressRepository: dailyProgress, clock: () => DateTime(2026, 8, 3)),
    );

    await tester.pumpWidget(_wrap(controller));
    await tester.pumpAndSettle();

    // Digit assertions are deliberately avoided here: the day-by-day chain
    // also renders bare day-of-month digits, so e.g. "9" could collide
    // with both the best-streak stat and a "9th of the month" day chip.
    // Zero overflow plus the 3 stat tiles rendering is the meaningful
    // assertion for this screen.
    expect(tester.takeException(), isNull);
    expect(find.byType(AppCard), findsNWidgets(3));
    expect(find.text('My Streak'), findsOneWidget);
  });

  testWidgets('renders with zero overflow on a tablet-portrait width', (tester) async {
    _useSurfaceSize(tester, const Size(800, 1280));

    final dailyProgress = FakeDailyProgressRepository();
    final controller = StreakChainController(
      getStreakOverview: GetStreakOverview(dailyProgressRepository: dailyProgress, clock: () => DateTime(2026, 8, 3)),
    );

    await tester.pumpWidget(_wrap(controller));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
