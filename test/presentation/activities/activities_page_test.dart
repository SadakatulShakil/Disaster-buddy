// Fix/polish pass: the Activities grid must render every card (available +
// "coming soon" stubs) with zero RenderFlex overflow, at both a narrow
// phone width and a tablet-portrait width.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:bipod_bondhu/core/constants/app_constants.dart';
import 'package:bipod_bondhu/core/localization/app_translations.dart';
import 'package:bipod_bondhu/domain/entities/activity.dart';
import 'package:bipod_bondhu/domain/entities/badge_info.dart';
import 'package:bipod_bondhu/domain/entities/kit_item.dart';
import 'package:bipod_bondhu/domain/entities/localized_text.dart';
import 'package:bipod_bondhu/domain/usecases/get_activities.dart';
import 'package:bipod_bondhu/domain/usecases/get_activity_progress.dart';
import 'package:bipod_bondhu/presentation/activities/activities_controller.dart';
import 'package:bipod_bondhu/presentation/activities/activities_page.dart';
import 'package:bipod_bondhu/presentation/activities/widgets/activity_card.dart';

import '../../fakes/fake_activity_progress_repository.dart';
import '../../fakes/fake_activity_repository.dart';
import '../../fakes/fake_progress_repository.dart';

/// The real Emergency Kit title/badge text — used verbatim so the test
/// reproduces the exact long-label scenario from the bug report.
Activity _emergencyKitActivity() => const Activity(
      id: AppConstants.activityEmergencyKit,
      title: LocalizedText(bn: 'আমার জরুরি ব্যাগ', en: 'My Emergency Kit'),
      themeColorHex: '#6C63FF',
      iconAsset: 'icon.png',
      instructions: LocalizedText(bn: 'নির্দেশনা', en: 'Instructions'),
      items: [
        KitItem(id: 'water', label: LocalizedText(bn: 'পানি', en: 'Water'), imageAsset: 'water.png', isCorrect: true),
      ],
      badge: BadgeInfo(id: 'ready_kit_badge', title: LocalizedText(bn: 'badge', en: 'badge'), iconAsset: 'badge.png'),
    );

void _useSurfaceSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _wrap(ActivitiesController controller, {Locale locale = const Locale('bn', 'BD')}) {
  Get.put<ActivitiesController>(controller);
  return ScreenUtilInit(
    designSize: AppConstants.designSize,
    minTextAdapt: true,
    splitScreenMode: true,
    builder: (context, child) => GetMaterialApp(
      translations: AppTranslations(),
      locale: locale,
      builder: (context, widget) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: widget!,
      ),
      home: const ActivitiesPage(),
    ),
  );
}

void main() {
  tearDown(Get.reset);

  testWidgets('renders available + coming-soon cards with zero overflow on a narrow phone width', (tester) async {
    _useSurfaceSize(tester, const Size(320, 700));

    final activityRepository = FakeActivityRepository([_emergencyKitActivity()]);
    final controller = ActivitiesController(
      getActivities: GetActivities(activityRepository),
      getActivityProgress: GetActivityProgress(
        activityRepository: activityRepository,
        activityProgressRepository: FakeActivityProgressRepository(),
        progressRepository: FakeProgressRepository(),
      ),
    );

    await tester.pumpWidget(_wrap(controller));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(ActivityCard), findsOneWidget);
    expect(find.text('আমার জরুরি ব্যাগ'), findsOneWidget);
    // The two future stubs render too, using their real (long) bn labels.
    expect(find.text('সিগন্যাল রং'), findsOneWidget);
    expect(find.text('নিরাপদ জায়গা খুঁজো'), findsOneWidget);
  });

  testWidgets('renders available + coming-soon cards with zero overflow on a tablet-portrait width', (tester) async {
    _useSurfaceSize(tester, const Size(800, 1280));

    final activityRepository = FakeActivityRepository([_emergencyKitActivity()]);
    final controller = ActivitiesController(
      getActivities: GetActivities(activityRepository),
      getActivityProgress: GetActivityProgress(
        activityRepository: activityRepository,
        activityProgressRepository: FakeActivityProgressRepository(),
        progressRepository: FakeProgressRepository(),
      ),
    );

    await tester.pumpWidget(_wrap(controller));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(ActivityCard), findsOneWidget);
  });
}
