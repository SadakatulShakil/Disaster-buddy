// Phase E2: Tuku's Den must render with zero overflow on both a narrow
// phone and a tablet-portrait width, show the encouraging empty-collection
// pointer when nothing's earned yet, and reflect a sticker placed into a
// shelf slot.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bipod_bondhu/core/constants/app_constants.dart';
import 'package:bipod_bondhu/core/localization/app_translations.dart';
import 'package:bipod_bondhu/core/services/narration_service.dart';
import 'package:bipod_bondhu/core/services/user_pref_service.dart';
import 'package:bipod_bondhu/domain/entities/activity.dart';
import 'package:bipod_bondhu/domain/entities/activity_content.dart';
import 'package:bipod_bondhu/domain/entities/activity_type.dart';
import 'package:bipod_bondhu/domain/entities/badge_info.dart';
import 'package:bipod_bondhu/domain/entities/daily_challenge.dart';
import 'package:bipod_bondhu/domain/entities/hazard_module.dart';
import 'package:bipod_bondhu/domain/entities/localized_text.dart';
import 'package:bipod_bondhu/domain/entities/quiz_option.dart';
import 'package:bipod_bondhu/domain/entities/quiz_question.dart';
import 'package:bipod_bondhu/domain/usecases/get_activities.dart';
import 'package:bipod_bondhu/domain/usecases/get_den_state.dart';
import 'package:bipod_bondhu/domain/usecases/get_earned_collection.dart';
import 'package:bipod_bondhu/domain/usecases/get_module_progress.dart';
import 'package:bipod_bondhu/domain/usecases/get_modules.dart';
import 'package:bipod_bondhu/domain/usecases/get_streak_overview.dart';
import 'package:bipod_bondhu/domain/usecases/get_todays_challenge.dart';
import 'package:bipod_bondhu/domain/usecases/place_sticker.dart';
import 'package:bipod_bondhu/domain/usecases/remove_sticker.dart';
import 'package:bipod_bondhu/domain/usecases/set_den_theme.dart';
import 'package:bipod_bondhu/presentation/den/den_controller.dart';
import 'package:bipod_bondhu/presentation/den/den_page.dart';
import 'package:bipod_bondhu/presentation/den/widgets/collection_tray.dart';

import '../../fakes/fake_activity_repository.dart';
import '../../fakes/fake_content_repository.dart';
import '../../fakes/fake_daily_challenge_repository.dart';
import '../../fakes/fake_daily_progress_repository.dart';
import '../../fakes/fake_den_repository.dart';
import '../../fakes/fake_flutter_tts.dart';
import '../../fakes/fake_progress_repository.dart';

LocalizedText _text(String value) => LocalizedText(bn: value, en: value);

HazardModule _module(String id, int order) => HazardModule(
      id: id,
      order: order,
      title: _text(id),
      themeColorHex: '#A0522D',
      iconAsset: 'icon.png',
      safeAction: _text('safe'),
      badge: BadgeInfo(id: '${id}_badge', title: _text('$id badge'), iconAsset: 'badge.png'),
      beats: const [],
    );

DailyChallenge _dailyChallenge() => DailyChallenge(
      id: 'dc_1',
      type: DailyChallengeType.quiz,
      relatedHazardId: AppConstants.hazardEarthquake,
      difficulty: 1,
      payload: QuizChallengePayload(
        QuizQuestion(
          id: 'dc_1_q',
          prompt: _text('prompt'),
          options: [
            QuizOption(id: 'a', label: _text('a'), isCorrect: true),
            QuizOption(id: 'b', label: _text('b'), isCorrect: false),
          ],
        ),
      ),
    );

Activity _activityWithBadge(String id) => Activity(
      id: id,
      type: ActivityType.kitBuilder,
      title: _text(id),
      themeColorHex: '#6C63FF',
      iconAsset: 'icon.png',
      instructions: _text('instructions'),
      content: const KitBuilderContent(items: []),
      badge: BadgeInfo(id: '${id}_badge', title: _text('$id badge'), iconAsset: 'badge.png'),
    );

DateTime _fixedClock() => DateTime(2026, 8, 3);

class _Fixture {
  _Fixture()
      : contentRepository = FakeContentRepository([_module(AppConstants.hazardEarthquake, 1)]),
        activityRepository = FakeActivityRepository(const []),
        progressRepository = FakeProgressRepository(),
        denRepository = FakeDenRepository(),
        dailyProgressRepository = FakeDailyProgressRepository();

  /// Mirrors the real app's full catalogue (4 hazard modules + 1 badge-
  /// bearing activity + 5 streak milestones = 10 possible stickers) —
  /// small fixtures elsewhere in this file never exercise a collection
  /// tall enough to expose a sheet-height bug like the one this
  /// regression test guards against.
  _Fixture.fullCatalog()
      : contentRepository = FakeContentRepository([
          for (var i = 0; i < AppConstants.initialHazards.length; i++)
            _module(AppConstants.initialHazards[i], i + 1),
        ]),
        activityRepository = FakeActivityRepository([_activityWithBadge(AppConstants.activityEmergencyKit)]),
        progressRepository = FakeProgressRepository(),
        denRepository = FakeDenRepository(),
        dailyProgressRepository = FakeDailyProgressRepository();

  final FakeContentRepository contentRepository;
  final FakeActivityRepository activityRepository;
  final FakeProgressRepository progressRepository;
  final FakeDenRepository denRepository;
  final FakeDailyProgressRepository dailyProgressRepository;

  DenController buildController() {
    final getModules = GetModules(contentRepository);
    final getModuleProgress = GetModuleProgress(contentRepository: contentRepository, progressRepository: progressRepository);
    return DenController(
      getDenState: GetDenState(denRepository),
      getEarnedCollection: GetEarnedCollection(
        getModules: getModules,
        getActivities: GetActivities(activityRepository),
        progressRepository: progressRepository,
      ),
      getStreakOverview: GetStreakOverview(dailyProgressRepository: dailyProgressRepository, clock: _fixedClock),
      getTodaysChallenge: GetTodaysChallenge(
        dailyChallengeRepository: FakeDailyChallengeRepository([_dailyChallenge()]),
        dailyProgressRepository: dailyProgressRepository,
        getModules: getModules,
        getModuleProgress: getModuleProgress,
        clock: _fixedClock,
      ),
      placeSticker: PlaceSticker(denRepository: denRepository, progressRepository: progressRepository),
      removeSticker: RemoveSticker(denRepository),
      setDenTheme: SetDenTheme(denRepository),
      narrationService: NarrationService(tts: FakeFlutterTts()),
    );
  }
}

Widget _wrap(DenController controller) {
  Get.put<DenController>(controller);
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
      home: const DenPage(),
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
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await UserPrefService.instance.init();
  });

  tearDown(Get.reset);

  testWidgets('renders with zero overflow on a narrow phone width', (tester) async {
    _useSurfaceSize(tester, const Size(320, 700));

    await tester.pumpWidget(_wrap(_Fixture().buildController()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text("Tuku's Den"), findsOneWidget);
    expect(find.byIcon(Icons.add_rounded), findsNWidgets(9));
  });

  testWidgets('renders with zero overflow on a tablet-portrait width', (tester) async {
    _useSurfaceSize(tester, const Size(800, 1280));

    await tester.pumpWidget(_wrap(_Fixture().buildController()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.add_rounded), findsNWidgets(9));
  });

  testWidgets('empty-collection state points encouragingly to earning a sticker', (tester) async {
    _useSurfaceSize(tester, const Size(360, 800));

    await tester.pumpWidget(_wrap(_Fixture().buildController()));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.style_rounded));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Earn your first sticker!'), findsOneWidget);
    expect(find.text('back_to_map'.tr), findsOneWidget);
  });

  testWidgets('an earned sticker can be placed into a shelf slot', (tester) async {
    _useSurfaceSize(tester, const Size(360, 800));

    final fixture = _Fixture()..progressRepository.earnedBadgeIds.add('${AppConstants.hazardEarthquake}_badge');
    final controller = fixture.buildController();

    await tester.pumpWidget(_wrap(controller));
    await tester.pumpAndSettle();

    // All 9 shelf slots start empty.
    expect(find.byIcon(Icons.add_rounded), findsNWidgets(9));

    await controller.placeStickerInSlot(slotId: 'shelf_1_slot_1', stickerId: '${AppConstants.hazardEarthquake}_badge');
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // One slot is now occupied, so only 8 remain showing the empty "add" hint.
    expect(find.byIcon(Icons.add_rounded), findsNWidgets(8));
    expect(fixture.denRepository.state.slots.firstWhere((s) => s.slotId == 'shelf_1_slot_1').placedStickerId,
        '${AppConstants.hazardEarthquake}_badge');
  });

  testWidgets(
    'regression: a real drag gesture from the tray reaches a shelf slot and drops there — the '
    'tray must never be a modal that blocks touches to the shelves behind it',
    (tester) async {
      _useSurfaceSize(tester, const Size(360, 800));

      final fixture = _Fixture()..progressRepository.earnedBadgeIds.add('${AppConstants.hazardEarthquake}_badge');
      final controller = fixture.buildController();

      await tester.pumpWidget(_wrap(controller));
      await tester.pumpAndSettle();

      // Opening the tray must NOT push a new route/dialog — the shelves
      // stay in the very same widget tree, reachable by a single
      // continuous drag gesture.
      await tester.tap(find.byIcon(Icons.style_rounded));
      await tester.pumpAndSettle();

      final tileFinder = find.byKey(const ValueKey('${AppConstants.hazardEarthquake}_badge'));
      final slotFinder = find.byKey(const ValueKey('shelf_1_slot_1'));
      expect(tileFinder, findsOneWidget);
      expect(slotFinder, findsOneWidget);

      final gesture = await tester.startGesture(tester.getCenter(tileFinder));
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.moveTo(tester.getCenter(slotFinder));
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        fixture.denRepository.state.slots.firstWhere((s) => s.slotId == 'shelf_1_slot_1').placedStickerId,
        '${AppConstants.hazardEarthquake}_badge',
      );
    },
  );

  testWidgets(
    'regression: with the full sticker catalogue, the tray stays capped to the screen and every '
    'section (title through theme picker) is reachable by scrolling — nothing is pushed off-screen',
    (tester) async {
      _useSurfaceSize(tester, const Size(360, 800));

      final fixture = _Fixture.fullCatalog()
        ..progressRepository.earnedBadgeIds.add('${AppConstants.hazardEarthquake}_badge');
      await tester.pumpWidget(_wrap(fixture.buildController()));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.style_rounded));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final trayScrollView = find.descendant(
        of: find.byType(CollectionTray),
        matching: find.byType(SingleChildScrollView),
      );

      // The sheet itself must never exceed the capped height — if it did,
      // its top content would render above the screen again.
      final sheetSize = tester.getSize(trayScrollView);
      expect(sheetSize.height, lessThanOrEqualTo(800 * 0.85));

      // The title (top of the tray's content) is visible without any
      // scrolling — proving it wasn't pushed off-screen above y=0. (The
      // FAB behind the tray shares the same "My Stickers" text, so this
      // is scoped to inside the tray itself.)
      expect(
        find.descendant(of: find.byType(CollectionTray), matching: find.text('den_collection_tray_title'.tr)),
        findsOneWidget,
      );

      // Scrolling within the (now correctly bounded) tray reaches the
      // theme picker at the very bottom of the same content.
      await tester.dragUntilVisible(
        find.text('den_theme_title'.tr),
        trayScrollView,
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();
      expect(find.text('den_theme_title'.tr), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
