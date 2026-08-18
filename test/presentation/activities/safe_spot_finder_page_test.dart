// Fix/polish pass: the Safe Spot Finder screen must render with zero
// RenderFlex overflow at both a narrow phone width and a tablet-portrait
// width.

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
import 'package:bipod_bondhu/domain/entities/activity.dart';
import 'package:bipod_bondhu/domain/entities/activity_content.dart';
import 'package:bipod_bondhu/domain/entities/activity_type.dart';
import 'package:bipod_bondhu/domain/entities/badge_info.dart';
import 'package:bipod_bondhu/domain/entities/localized_text.dart';
import 'package:bipod_bondhu/domain/entities/normalized_rect.dart';
import 'package:bipod_bondhu/domain/entities/safe_spot_hotspot.dart';
import 'package:bipod_bondhu/domain/entities/safe_spot_scene.dart';
import 'package:bipod_bondhu/domain/usecases/complete_activity.dart';
import 'package:bipod_bondhu/domain/usecases/get_activity.dart';
import 'package:bipod_bondhu/presentation/activities/safe_spot_finder/safe_spot_finder_controller.dart';
import 'package:bipod_bondhu/presentation/activities/safe_spot_finder/safe_spot_finder_page.dart';

import '../../fakes/fake_activity_progress_repository.dart';
import '../../fakes/fake_activity_repository.dart';
import '../../fakes/fake_flutter_tts.dart';
import '../../fakes/fake_progress_repository.dart';

/// The real, realistically-short Safe Spot Finder title — the header must
/// stay within bounds for normal content; the long strings below stress the
/// body's wrapping instead.
const _title = LocalizedText(bn: 'নিরাপদ জায়গা খুঁজো', en: 'Safe Spot Finder');

const _text = LocalizedText(
  bn: 'ভূমিকম্পের সময় ঘরে কোথায় থাকা নিরাপদ — এই দীর্ঘ বাংলা লেখাটি উপচে পড়া পরীক্ষা করার জন্য',
  en: 'During an earthquake at home, where is it safe — a deliberately long line to probe for overflow',
);

Activity _safeSpotActivity() => const Activity(
      id: 'safe_spot_finder',
      type: ActivityType.safeSpotFinder,
      title: _title,
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
                rect: NormalizedRect(x: 0.35, y: 0.55, width: 0.3, height: 0.3),
                isSafe: true,
                label: _text,
                feedback: _text,
              ),
              SafeSpotHotspot(
                id: 'unsafe1',
                rect: NormalizedRect(x: 0.05, y: 0.1, width: 0.25, height: 0.35),
                isSafe: false,
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

Widget _wrap(SafeSpotFinderController controller) {
  Get.put<SafeSpotFinderController>(controller);
  return ScreenUtilInit(
    designSize: AppConstants.designSize,
    minTextAdapt: true,
    splitScreenMode: true,
    builder: (context, child) => GetMaterialApp(
      translations: AppTranslations(),
      locale: const Locale('bn', 'BD'),
      builder: (context, widget) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: widget!,
      ),
      home: const SafeSpotFinderPage(),
    ),
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await UserPrefService.instance.init();
  });
  tearDown(Get.reset);

  for (final size in [const Size(320, 700), const Size(800, 1280)]) {
    testWidgets('renders with zero overflow at $size', (tester) async {
      _useSurfaceSize(tester, size);

      final activityRepository = FakeActivityRepository([_safeSpotActivity()]);
      final controller = SafeSpotFinderController(
        getActivity: GetActivity(activityRepository),
        completeActivity: CompleteActivity(
          activityProgressRepository: FakeActivityProgressRepository(),
          progressRepository: FakeProgressRepository(),
        ),
        narrationService: NarrationService(tts: FakeFlutterTts()),
        soundService: SoundService(),
        activityId: 'safe_spot_finder',
      );

      await tester.pumpWidget(_wrap(controller));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  }
}
