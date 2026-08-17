import 'package:get/get.dart';

import '../../presentation/activities/activities_binding.dart';
import '../../presentation/activities/activities_page.dart';
import '../../presentation/activities/kit_builder/kit_builder_binding.dart';
import '../../presentation/activities/kit_builder/kit_builder_page.dart';
import '../../presentation/daily_challenge/daily_challenge_binding.dart';
import '../../presentation/daily_challenge/daily_challenge_page.dart';
import '../../presentation/den/den_binding.dart';
import '../../presentation/den/den_page.dart';
import '../../presentation/home/home_binding.dart';
import '../../presentation/home/home_page.dart';
import '../../presentation/language/language_binding.dart';
import '../../presentation/language/language_page.dart';
import '../../presentation/lesson/beat_runner_page.dart';
import '../../presentation/lesson/lesson_binding.dart';
import '../../presentation/module/module_binding.dart';
import '../../presentation/module/module_page.dart';
import '../../presentation/parent_gate/parent_gate_binding.dart';
import '../../presentation/parent_gate/parent_gate_page.dart';
import '../../presentation/parent_zone/parent_zone_binding.dart';
import '../../presentation/parent_zone/parent_zone_page.dart';
import '../../presentation/activities/safe_spot_finder/safe_spot_finder_binding.dart';
import '../../presentation/activities/safe_spot_finder/safe_spot_finder_page.dart';
import '../../presentation/activities/signal_colours/signal_colours_binding.dart';
import '../../presentation/activities/signal_colours/signal_colours_page.dart';
import '../../presentation/reward/reward_page.dart';
import '../../presentation/settings/settings_binding.dart';
import '../../presentation/settings/settings_page.dart';
import '../../presentation/splash/splash_binding.dart';
import '../../presentation/splash/splash_page.dart';
import '../../presentation/sticker_book/sticker_book_binding.dart';
import '../../presentation/sticker_book/sticker_book_page.dart';
import '../../presentation/streak/streak_chain_binding.dart';
import '../../presentation/streak/streak_chain_page.dart';
import 'app_routes.dart';

/// Route table. Every screen gets its own GetX binding.
class AppPages {
  AppPages._();

  static const String initial = AppRoutes.splash;

  static final List<GetPage> pages = [
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashPage(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: AppRoutes.language,
      page: () => const LanguagePage(),
      binding: LanguageBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomePage(),
      binding: HomeBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.module,
      page: () => const ModulePage(),
      binding: ModuleBinding(),
      transition: Transition.zoom,
    ),
    GetPage(
      name: AppRoutes.stickerBook,
      page: () => const StickerBookPage(),
      binding: StickerBookBinding(),
      transition: Transition.zoom,
    ),
    GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsPage(),
      binding: SettingsBinding(),
      transition: Transition.zoom,
    ),
    GetPage(
      name: AppRoutes.parentGate,
      page: () => const ParentGatePage(),
      binding: ParentGateBinding(),
      transition: Transition.zoom,
    ),
    GetPage(
      name: AppRoutes.parentZone,
      page: () => const ParentZonePage(),
      binding: ParentZoneBinding(),
      transition: Transition.zoom,
    ),
    GetPage(
      name: AppRoutes.lesson,
      page: () => const BeatRunnerPage(),
      binding: LessonBinding(),
      transition: Transition.zoom,
    ),
    GetPage(
      name: AppRoutes.reward,
      page: () => const RewardPage(),
      transition: Transition.zoom,
    ),
    GetPage(
      name: AppRoutes.activities,
      page: () => const ActivitiesPage(),
      binding: ActivitiesBinding(),
      transition: Transition.zoom,
    ),
    GetPage(
      name: AppRoutes.kitBuilder,
      page: () => const KitBuilderPage(),
      binding: KitBuilderBinding(),
      transition: Transition.zoom,
    ),
    GetPage(
      name: AppRoutes.signalColours,
      page: () => const SignalColoursPage(),
      binding: SignalColoursBinding(),
      transition: Transition.zoom,
    ),
    GetPage(
      name: AppRoutes.safeSpotFinder,
      page: () => const SafeSpotFinderPage(),
      binding: SafeSpotFinderBinding(),
      transition: Transition.zoom,
    ),
    GetPage(
      name: AppRoutes.dailyChallenge,
      page: () => const DailyChallengePage(),
      binding: DailyChallengeBinding(),
      transition: Transition.zoom,
    ),
    GetPage(
      name: AppRoutes.streakChain,
      page: () => const StreakChainPage(),
      binding: StreakChainBinding(),
      transition: Transition.zoom,
    ),
    GetPage(
      name: AppRoutes.den,
      page: () => const DenPage(),
      binding: DenBinding(),
      transition: Transition.zoom,
    ),
  ];
}
