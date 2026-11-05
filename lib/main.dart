import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'core/bindings/initial_binding.dart';
import 'core/constants/app_constants.dart';
import 'core/localization/app_translations.dart';
import 'core/routes/app_pages.dart';
import 'core/services/user_pref_service.dart';
import 'core/theme/app_theme.dart';
import 'data/local/app_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Kids app: lock to portrait.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Sane default before the first frame renders (the Splash screen has a
  // teal background, so light/white status-bar icons read clearly there).
  // Screens with a light background override this via
  // `AppScaffold.statusBarStyle`; screens with a themed AppBar get theirs
  // from `AppTheme`'s `AppBarTheme.systemOverlayStyle`.
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

  // Init the prefs singleton before the app builds.
  await UserPrefService.instance.init();

  // Open the local database once and keep it alive for the whole session.
  // InitialBinding wires the repositories/use cases on top of it.
  final db = await openAppDatabase();
  Get.put<AppDatabase>(db, permanent: true);

  runApp(const BipodBondhuApp());
}

class BipodBondhuApp extends StatelessWidget {
  const BipodBondhuApp({super.key});

  Locale get _startLocale {
    final code = UserPrefService.instance.languageCode;
    if (code == AppConstants.langBn) return const Locale('bn', 'BD');
    return const Locale('en', 'US'); // default, until the user picks a language
  }

  @override
  Widget build(BuildContext context) {
    // Tablets get a larger reference design size so .w/.h/.sp/.r scale
    // factors stay close to 1x instead of ballooning 2-3x on a big screen.
    final isTablet = MediaQuery.sizeOf(context).shortestSide >= AppConstants.tabletBreakpoint;
    return ScreenUtilInit(
      designSize: isTablet ? AppConstants.tabletDesignSize : AppConstants.designSize,
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetMaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,

          // Localization
          translations: AppTranslations(),
          locale: _startLocale,
          fallbackLocale: const Locale('en', 'US'),

          // Routing
          initialBinding: InitialBinding(),
          initialRoute: AppPages.initial,
          getPages: AppPages.pages,
        );
      },
    );
  }
}
