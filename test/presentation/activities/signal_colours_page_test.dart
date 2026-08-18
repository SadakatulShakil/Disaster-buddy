// Fix/polish pass: the Signal Colours screen must render with zero
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
import 'package:bipod_bondhu/domain/entities/signal_info.dart';
import 'package:bipod_bondhu/domain/usecases/complete_activity.dart';
import 'package:bipod_bondhu/domain/usecases/get_activity.dart';
import 'package:bipod_bondhu/presentation/activities/signal_colours/signal_colours_controller.dart';
import 'package:bipod_bondhu/presentation/activities/signal_colours/signal_colours_page.dart';

import '../../fakes/fake_activity_progress_repository.dart';
import '../../fakes/fake_activity_repository.dart';
import '../../fakes/fake_flutter_tts.dart';
import '../../fakes/fake_progress_repository.dart';

/// The real, realistically-short Signal Colours title — the header must
/// stay within bounds for normal content; the long strings below stress the
/// body's wrapping instead.
const _title = LocalizedText(bn: 'সিগন্যাল রং', en: 'Signal Colours');

const _text = LocalizedText(
  bn: 'ঝড় আসতে পারে, তৈরি হও — এই দীর্ঘ বাংলা লেখাটি উপচে পড়া পরীক্ষা করার জন্য',
  en: 'A storm might be coming — get ready, a deliberately long line to probe for overflow',
);

Activity _signalActivity() => const Activity(
      id: 'signal_colours',
      type: ActivityType.signalColours,
      title: _title,
      themeColorHex: '#5B6EE1',
      iconAsset: 'icon.png',
      instructions: _text,
      content: SignalColoursContent(
        signals: [
          SignalInfo(id: 'calm', colorHex: '#2E9E5B', meaning: _text, action: _text, actionIcon: 'a.png'),
          SignalInfo(id: 'get_ready', colorHex: '#F4C430', meaning: _text, action: _text, actionIcon: 'b.png'),
          SignalInfo(id: 'danger', colorHex: '#D9534F', meaning: _text, action: _text, actionIcon: 'c.png'),
        ],
      ),
      badge: BadgeInfo(id: 'signal_spotter_badge', title: _text, iconAsset: 'badge.png'),
    );

void _useSurfaceSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _wrap(SignalColoursController controller) {
  Get.put<SignalColoursController>(controller);
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
      home: const SignalColoursPage(),
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

      final activityRepository = FakeActivityRepository([_signalActivity()]);
      final controller = SignalColoursController(
        getActivity: GetActivity(activityRepository),
        completeActivity: CompleteActivity(
          activityProgressRepository: FakeActivityProgressRepository(),
          progressRepository: FakeProgressRepository(),
        ),
        narrationService: NarrationService(tts: FakeFlutterTts()),
        soundService: SoundService(),
        activityId: 'signal_colours',
      );

      await tester.pumpWidget(_wrap(controller));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  }
}
