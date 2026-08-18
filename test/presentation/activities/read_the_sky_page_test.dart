// Fix/polish pass: the Read the Sky screen must render with zero
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
import 'package:bipod_bondhu/domain/entities/weather_sign.dart';
import 'package:bipod_bondhu/domain/entities/weather_sign_option.dart';
import 'package:bipod_bondhu/domain/usecases/complete_activity.dart';
import 'package:bipod_bondhu/domain/usecases/get_activity.dart';
import 'package:bipod_bondhu/presentation/activities/read_the_sky/read_the_sky_controller.dart';
import 'package:bipod_bondhu/presentation/activities/read_the_sky/read_the_sky_page.dart';

import '../../fakes/fake_activity_progress_repository.dart';
import '../../fakes/fake_activity_repository.dart';
import '../../fakes/fake_flutter_tts.dart';
import '../../fakes/fake_progress_repository.dart';

/// The real, realistically-short Read the Sky title — the header must stay
/// within bounds for normal content; the long strings below stress the
/// body's wrapping instead.
const _title = LocalizedText(bn: 'আকাশ পড়ো', en: 'Read the Sky');

const _text = LocalizedText(
  bn: 'আকাশে ঘন কালো মেঘ জমছে আর অন্ধকার হয়ে আসছে — এই দীর্ঘ বাংলা লেখাটি উপচে পড়া পরীক্ষা করার জন্য',
  en: 'Heavy dark clouds are gathering and the sky is turning dark — a deliberately long line to probe for overflow',
);

Activity _readTheSkyActivity() => const Activity(
      id: 'read_the_sky',
      type: ActivityType.readTheSky,
      title: _title,
      themeColorHex: '#2E86AB',
      iconAsset: 'icon.png',
      instructions: _text,
      content: ReadTheSkyContent(
        signs: [
          WeatherSign(
            id: 'dark_clouds',
            image: 'sign_dark_clouds.png',
            description: _text,
            correctHazard: _text,
            options: [
              WeatherSignOption(id: 'storm', label: _text, isCorrect: true),
              WeatherSignOption(id: 'flood', label: _text, isCorrect: false),
              WeatherSignOption(id: 'lightning', label: _text, isCorrect: false),
            ],
            feedback: _text,
            action: _text,
          ),
        ],
      ),
      badge: BadgeInfo(id: 'read_the_sky_badge', title: _text, iconAsset: 'badge.png'),
    );

void _useSurfaceSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _wrap(ReadTheSkyController controller) {
  Get.put<ReadTheSkyController>(controller);
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
      home: const ReadTheSkyPage(),
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

      final activityRepository = FakeActivityRepository([_readTheSkyActivity()]);
      final controller = ReadTheSkyController(
        getActivity: GetActivity(activityRepository),
        completeActivity: CompleteActivity(
          activityProgressRepository: FakeActivityProgressRepository(),
          progressRepository: FakeProgressRepository(),
        ),
        narrationService: NarrationService(tts: FakeFlutterTts()),
        soundService: SoundService(),
        activityId: 'read_the_sky',
      );

      await tester.pumpWidget(_wrap(controller));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  }
}
