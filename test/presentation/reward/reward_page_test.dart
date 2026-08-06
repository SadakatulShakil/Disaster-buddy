// Phase E2: the module-completion reward screen must render with zero
// overflow and offer the "Tuku's Den" invite alongside "Back to map" —
// gently inviting the child to place their freshly-earned sticker without
// forcing them there.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:bipod_bondhu/core/constants/app_constants.dart';
import 'package:bipod_bondhu/core/localization/app_translations.dart';
import 'package:bipod_bondhu/domain/entities/badge_info.dart';
import 'package:bipod_bondhu/domain/entities/localized_text.dart';
import 'package:bipod_bondhu/presentation/reward/reward_args.dart';
import 'package:bipod_bondhu/presentation/reward/reward_page.dart';

Widget _wrap() {
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
      home: const SizedBox.shrink(),
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

  testWidgets('shows the Tuku\'s Den invite and back-to-map action with zero overflow', (tester) async {
    _useSurfaceSize(tester, const Size(340, 720));

    const args = RewardArgs(
      moduleId: AppConstants.hazardEarthquake,
      badge: BadgeInfo(
        id: 'earthquake_badge',
        title: LocalizedText(bn: 'ভূমিকম্প বীর', en: 'Earthquake Hero'),
        iconAsset: 'badge_earthquake.png',
      ),
      themeColorHex: '#A0522D',
    );

    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    Get.to(() => const RewardPage(), arguments: args);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Earthquake Hero'), findsOneWidget);
    expect(find.text('Tuku\'s Den'), findsOneWidget);
    expect(find.text('Back to map'), findsOneWidget);
  });
}
