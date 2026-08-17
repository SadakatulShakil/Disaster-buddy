// Fix/polish pass: the Activities grid must render every activity card with
// zero RenderFlex overflow, at both a narrow phone width and a tablet-
// portrait width.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:bipod_bondhu/core/constants/app_constants.dart';
import 'package:bipod_bondhu/core/localization/app_translations.dart';
import 'package:bipod_bondhu/domain/entities/activity.dart';
import 'package:bipod_bondhu/domain/entities/activity_content.dart';
import 'package:bipod_bondhu/domain/entities/activity_type.dart';
import 'package:bipod_bondhu/domain/entities/badge_info.dart';
import 'package:bipod_bondhu/domain/entities/kit_item.dart';
import 'package:bipod_bondhu/domain/entities/localized_text.dart';
import 'package:bipod_bondhu/domain/entities/normalized_rect.dart';
import 'package:bipod_bondhu/domain/entities/safe_spot_hotspot.dart';
import 'package:bipod_bondhu/domain/entities/safe_spot_scene.dart';
import 'package:bipod_bondhu/domain/entities/signal_info.dart';
import 'package:bipod_bondhu/domain/usecases/get_activities.dart';
import 'package:bipod_bondhu/domain/usecases/get_activity_progress.dart';
import 'package:bipod_bondhu/presentation/activities/activities_controller.dart';
import 'package:bipod_bondhu/presentation/activities/activities_page.dart';
import 'package:bipod_bondhu/presentation/activities/widgets/activity_card.dart';

import '../../fakes/fake_activity_progress_repository.dart';
import '../../fakes/fake_activity_repository.dart';
import '../../fakes/fake_progress_repository.dart';

const _text = LocalizedText(bn: 'ক', en: 'a');

/// The real Emergency Kit title/badge text — used verbatim so the test
/// reproduces the exact long-label scenario from the bug report.
Activity _emergencyKitActivity() => const Activity(
      id: AppConstants.activityEmergencyKit,
      type: ActivityType.kitBuilder,
      title: LocalizedText(bn: 'আমার জরুরি ব্যাগ', en: 'My Emergency Kit'),
      themeColorHex: '#6C63FF',
      iconAsset: 'icon.png',
      instructions: LocalizedText(bn: 'নির্দেশনা', en: 'Instructions'),
      content: KitBuilderContent(
        items: [
          KitItem(id: 'water', label: LocalizedText(bn: 'পানি', en: 'Water'), imageAsset: 'water.png', isCorrect: true),
        ],
      ),
      badge: BadgeInfo(id: 'ready_kit_badge', title: LocalizedText(bn: 'badge', en: 'badge'), iconAsset: 'badge.png'),
    );

/// The real Signal Colours title — used verbatim so the test reproduces the
/// exact long-label scenario from the bug report.
Activity _signalColoursActivity() => const Activity(
      id: AppConstants.activitySignalColours,
      type: ActivityType.signalColours,
      title: LocalizedText(bn: 'সিগন্যাল রং', en: 'Signal Colours'),
      themeColorHex: '#5B6EE1',
      iconAsset: 'icon.png',
      instructions: _text,
      content: SignalColoursContent(
        signals: [
          SignalInfo(id: 'calm', colorHex: '#2E9E5B', meaning: _text, action: _text, actionIcon: 'a.png'),
        ],
      ),
      badge: BadgeInfo(id: 'signal_spotter_badge', title: _text, iconAsset: 'badge.png'),
    );

/// The real Safe Spot Finder title — used verbatim so the test reproduces
/// the exact long-label scenario from the bug report.
Activity _safeSpotFinderActivity() => const Activity(
      id: AppConstants.activitySafeSpotFinder,
      type: ActivityType.safeSpotFinder,
      title: LocalizedText(bn: 'নিরাপদ জায়গা খুঁজো', en: 'Safe Spot Finder'),
      themeColorHex: '#E07A5F',
      iconAsset: 'icon.png',
      instructions: _text,
      content: SafeSpotContent(
        scenes: [
          SafeSpotScene(
            id: 'scene1',
            sceneImage: 'scene1.png',
            prompt: _text,
            spots: [
              SafeSpotHotspot(
                id: 'safe1',
                rect: NormalizedRect(x: 0.1, y: 0.1, width: 0.2, height: 0.2),
                isSafe: true,
                label: _text,
                feedback: _text,
              ),
            ],
          ),
        ],
      ),
      badge: BadgeInfo(id: 'safe_spot_hero_badge', title: _text, iconAsset: 'badge.png'),
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

  testWidgets('renders every activity card with zero overflow on a narrow phone width', (tester) async {
    _useSurfaceSize(tester, const Size(320, 700));

    final activityRepository = FakeActivityRepository([
      _emergencyKitActivity(),
      _signalColoursActivity(),
      _safeSpotFinderActivity(),
    ]);
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
    expect(find.byType(ActivityCard), findsNWidgets(3));
    expect(find.text('আমার জরুরি ব্যাগ'), findsOneWidget);
    // Signal Colours and Safe Spot Finder now render as real cards, using
    // their real (long) bn labels — not "coming soon" stubs.
    expect(find.text('সিগন্যাল রং'), findsOneWidget);
    expect(find.text('নিরাপদ জায়গা খুঁজো'), findsOneWidget);
  });

  testWidgets('renders every activity card with zero overflow on a tablet-portrait width', (tester) async {
    _useSurfaceSize(tester, const Size(800, 1280));

    final activityRepository = FakeActivityRepository([
      _emergencyKitActivity(),
      _signalColoursActivity(),
      _safeSpotFinderActivity(),
    ]);
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
    expect(find.byType(ActivityCard), findsNWidgets(3));
  });
}
