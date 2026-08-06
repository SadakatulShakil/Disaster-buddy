// Phase 2: switching language in Settings must update the app locale live
// and persist the choice (verified via a fake/mocked SharedPreferences
// backing store) so it survives a restart.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bipod_bondhu/core/constants/app_constants.dart';
import 'package:bipod_bondhu/core/localization/app_translations.dart';
import 'package:bipod_bondhu/core/services/user_pref_service.dart';
import 'package:bipod_bondhu/presentation/settings/settings_binding.dart';
import 'package:bipod_bondhu/presentation/settings/settings_controller.dart';
import 'package:bipod_bondhu/presentation/settings/settings_page.dart';

Widget _wrap() {
  return ScreenUtilInit(
    designSize: AppConstants.designSize,
    builder: (context, child) => GetMaterialApp(
      translations: AppTranslations(),
      locale: const Locale('bn', 'BD'),
      initialBinding: SettingsBinding(),
      builder: (context, widget) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: widget!,
      ),
      home: const SettingsPage(),
    ),
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await UserPrefService.instance.init();
  });

  tearDown(Get.reset);

  testWidgets('switching language updates the locale live and persists it', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    expect(Get.locale?.languageCode, AppConstants.langBn);

    // Drive the same handler the "English" card's onTap calls. `setLanguage`
    // goes through `Get.updateLocale`, which triggers a full GetX engine
    // reassemble — firing that synchronously from inside a WidgetTester
    // gesture dispatch trips the framework's scheduler-phase assertion, so
    // it's awaited directly here instead of simulating the tap.
    await Get.find<SettingsController>().setLanguage(AppConstants.langEn);
    await tester.pumpAndSettle();

    expect(Get.locale?.languageCode, AppConstants.langEn);
    expect(UserPrefService.instance.languageCode, AppConstants.langEn);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });
}
