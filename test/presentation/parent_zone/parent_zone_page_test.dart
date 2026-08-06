// Parent-controlled progress reset: proves the full end-to-end flow from
// the actual ParentZone UI — confirm dialogs show the right scope, the
// hold-to-confirm gate genuinely requires holding (not a single tap), a
// success dialog appears, and the on-screen summary refreshes afterward.
// Behind the existing ParentGate is out of scope here (ParentGate itself
// is unchanged); this exercises ParentZonePage directly, as the gate
// already does when it succeeds.
//
// Uses fakes throughout (matching every other widget test in this
// codebase) rather than a real Floor database — the real reset/DB logic
// is already proven against a real in-memory database in
// reset_usecases_test.dart; this file is purely about the UI flow and the
// controller's post-reset refresh behaviour.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:bipod_bondhu/core/constants/app_constants.dart';
import 'package:bipod_bondhu/core/error/failures.dart';
import 'package:bipod_bondhu/core/error/result.dart';
import 'package:bipod_bondhu/core/localization/app_translations.dart';
import 'package:bipod_bondhu/domain/entities/badge_info.dart';
import 'package:bipod_bondhu/domain/entities/beat.dart';
import 'package:bipod_bondhu/domain/entities/hazard_module.dart';
import 'package:bipod_bondhu/domain/entities/localized_text.dart';
import 'package:bipod_bondhu/domain/usecases/get_activities.dart';
import 'package:bipod_bondhu/domain/usecases/get_activity_progress.dart';
import 'package:bipod_bondhu/domain/usecases/get_module_progress.dart';
import 'package:bipod_bondhu/domain/usecases/get_modules.dart';
import 'package:bipod_bondhu/domain/usecases/reset_everything.dart';
import 'package:bipod_bondhu/domain/usecases/reset_learning_progress.dart';
import 'package:bipod_bondhu/domain/usecases/reset_single_module.dart';
import 'package:bipod_bondhu/presentation/parent_zone/parent_zone_controller.dart';
import 'package:bipod_bondhu/presentation/parent_zone/parent_zone_page.dart';

import '../../fakes/fake_activity_progress_repository.dart';
import '../../fakes/fake_activity_repository.dart';
import '../../fakes/fake_content_repository.dart';
import '../../fakes/fake_progress_repository.dart';
import '../../fakes/fake_reset_repository.dart';

const _eqTitle = LocalizedText(bn: 'ভূমিকম্প', en: 'Earthquake');
const _flTitle = LocalizedText(bn: 'বন্যা', en: 'Flood');

HazardModule _module(String id, LocalizedText title) => HazardModule(
      id: id,
      order: 1,
      title: title,
      themeColorHex: '#A0522D',
      iconAsset: 'icon.png',
      safeAction: title,
      badge: BadgeInfo(id: '${id}_badge', title: title, iconAsset: 'badge.png'),
      beats: [StoryBeat(id: '${id}_story', order: 1, slides: const [])],
    );

class _Fixture {
  _Fixture()
      : contentRepository = FakeContentRepository([_module('earthquake', _eqTitle), _module('flood', _flTitle)]),
        activityRepository = FakeActivityRepository(const []),
        activityProgressRepository = FakeActivityProgressRepository(),
        progressRepository = FakeProgressRepository()
          ..completedBeatIdsByModule['earthquake'] = {'earthquake_story'}
          ..earnedBadgeIds.add('earthquake_badge');

  final FakeContentRepository contentRepository;
  final FakeActivityRepository activityRepository;
  final FakeActivityProgressRepository activityProgressRepository;
  final FakeProgressRepository progressRepository;
  late final FakeResetRepository resetRepository = FakeResetRepository(
    onResetLearningProgress: () {
      progressRepository.completedBeatIdsByModule.clear();
      progressRepository.earnedBadgeIds.clear();
    },
    onResetSingleModule: (moduleId) {
      progressRepository.completedBeatIdsByModule.remove(moduleId);
      progressRepository.earnedBadgeIds.removeWhere((id) => id.startsWith(moduleId));
    },
    onResetEverything: () {
      progressRepository.completedBeatIdsByModule.clear();
      progressRepository.earnedBadgeIds.clear();
    },
  );

  ParentZoneController buildController() {
    final getModules = GetModules(contentRepository);
    return ParentZoneController(
      getModules: getModules,
      getModuleProgress: GetModuleProgress(contentRepository: contentRepository, progressRepository: progressRepository),
      getActivities: GetActivities(activityRepository),
      getActivityProgress: GetActivityProgress(
        activityRepository: activityRepository,
        activityProgressRepository: activityProgressRepository,
        progressRepository: progressRepository,
      ),
      resetLearningProgress: ResetLearningProgress(resetRepository),
      resetSingleModule: ResetSingleModule(resetRepository),
      resetEverything: ResetEverything(resetRepository),
    );
  }
}

Widget _wrap(ParentZoneController controller) {
  Get.put<ParentZoneController>(controller);
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
      home: const ParentZonePage(),
    ),
  );
}

void _useSurfaceSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// The "Manage Progress" section sits below the fold in the page's
/// `ListView`, which only builds children within its viewport/cache
/// extent — `scrollUntilVisible` only scrolls far enough for the widget to
/// *exist* in the tree (which can still leave it a few pixels outside the
/// visible viewport, too far for `tap()`'s hit test); `ensureVisible`
/// finishes the job by scrolling it fully into the viewport.
Future<void> _scrollToText(WidgetTester tester, String text) async {
  final finder = find.text(text);
  await tester.scrollUntilVisible(finder, 200, scrollable: find.byType(Scrollable));
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

/// A dialog's own content can also be taller than a small test window; its
/// `SingleChildScrollView` builds every child eagerly (unlike the page's
/// lazy `ListView`), so `ensureVisible` alone — scoped to the target's
/// nearest scrollable ancestor — is enough to bring it fully on-screen.
Future<void> _ensureDialogButtonVisible(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text));
  await tester.pumpAndSettle();
}

/// `scrollUntilVisible` only ever drags in the list's forward (downward)
/// direction, so it can't reach content *above* the current scroll
/// position — this snaps back to the top first.
Future<void> _scrollToTop(WidgetTester tester) async {
  await tester.drag(find.byType(Scrollable), const Offset(0, 5000));
  await tester.pumpAndSettle();
}

void main() {
  tearDown(Get.reset);

  testWidgets('renders the 3 reset options with zero overflow on a narrow phone width', (tester) async {
    _useSurfaceSize(tester, const Size(340, 720));
    await tester.pumpWidget(_wrap(_Fixture().buildController()));
    await tester.pumpAndSettle();

    // Scrolled to and checked one at a time: the ListView only keeps
    // nearby children built, so a card scrolled far out of view again
    // (e.g. the first, once the last is on screen) may not exist in the
    // tree — that's expected lazy-list behaviour, not a bug.
    for (final title in ['Reset learning only', 'Reset one hazard', 'Reset everything']) {
      await _scrollToText(tester, title);
      expect(find.text(title), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders with zero overflow on a tablet-portrait width', (tester) async {
    _useSurfaceSize(tester, const Size(800, 1280));
    await tester.pumpWidget(_wrap(_Fixture().buildController()));
    await tester.pumpAndSettle();

    await _scrollToText(tester, 'Reset everything');

    expect(tester.takeException(), isNull);
  });

  testWidgets('reset-learning flow: confirm -> success -> summary refreshes to 0 badges', (tester) async {
    final fixture = _Fixture();
    await tester.pumpWidget(_wrap(fixture.buildController()));
    await tester.pumpAndSettle();

    expect(find.text('1'), findsOneWidget); // badgesEarned starts at 1

    await _scrollToText(tester, 'Reset learning only');
    await tester.tap(find.text('Reset learning only'));
    await tester.pumpAndSettle();
    expect(find.text('Reset all learning progress?'), findsOneWidget);

    await _ensureDialogButtonVisible(tester, 'Yes, reset');
    await tester.tap(find.text('Yes, reset'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('All done!'), findsOneWidget);
    expect(find.text('Learning progress has been reset.'), findsOneWidget);
    expect(fixture.resetRepository.resetLearningProgressCallCount, 1);

    await _ensureDialogButtonVisible(tester, 'done'.tr);
    await tester.tap(find.text('done'.tr));
    await tester.pumpAndSettle();

    // The stat card (scrolled out of view while reaching the reset
    // section) refreshed: no badges left.
    await _scrollToTop(tester);
    expect(find.text('0'), findsWidgets);
    expect(fixture.progressRepository.earnedBadgeIds, isEmpty);
  });

  testWidgets('reset-single-module flow: pick a module -> confirm names it -> success', (tester) async {
    final fixture = _Fixture();
    await tester.pumpWidget(_wrap(fixture.buildController()));
    await tester.pumpAndSettle();

    await _scrollToText(tester, 'Reset one hazard');
    await tester.tap(find.text('Reset one hazard'));
    await tester.pumpAndSettle();
    expect(find.text('Which adventure?'), findsOneWidget);
    expect(find.text('Earthquake'), findsWidgets);
    expect(find.text('Flood'), findsOneWidget);

    await tester.tap(find.text('Earthquake').last);
    await tester.pumpAndSettle();
    expect(find.text('Reset Earthquake?'), findsOneWidget);

    await _ensureDialogButtonVisible(tester, 'Yes, reset');
    await tester.tap(find.text('Yes, reset'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Earthquake has been reset.'), findsOneWidget);
    expect(fixture.resetRepository.resetModuleCalls, ['earthquake']);
  });

  testWidgets('a failed reset shows a friendly error dialog, not a crash', (tester) async {
    final fixture = _Fixture();
    fixture.resetRepository.failureToReturn = const Failure(DatabaseFailure('Could not reset learning progress.'));
    await tester.pumpWidget(_wrap(fixture.buildController()));
    await tester.pumpAndSettle();

    await _scrollToText(tester, 'Reset learning only');
    await tester.tap(find.text('Reset learning only'));
    await tester.pumpAndSettle();
    await _ensureDialogButtonVisible(tester, 'Yes, reset');
    await tester.tap(find.text('Yes, reset'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Oops! Something went wrong.'), findsOneWidget);
    expect(find.text('Could not reset learning progress.'), findsOneWidget);
  });

  testWidgets('reset-everything flow requires a genuine hold, not a single tap, before it fires', (tester) async {
    final fixture = _Fixture();
    await tester.pumpWidget(_wrap(fixture.buildController()));
    await tester.pumpAndSettle();

    await _scrollToText(tester, 'Reset everything');
    await tester.tap(find.text('Reset everything'));
    await tester.pumpAndSettle();
    expect(find.text('Reset everything?'), findsOneWidget);

    await _ensureDialogButtonVisible(tester, 'Yes, reset');
    await tester.tap(find.text('Yes, reset'));
    await tester.pumpAndSettle();
    expect(find.text('Hold to confirm'), findsOneWidget);

    await _ensureDialogButtonVisible(tester, 'Hold to reset everything');

    // A plain tap must NOT confirm the wipe.
    await tester.tap(find.text('Hold to reset everything'));
    await tester.pumpAndSettle();
    expect(find.text('Hold to confirm'), findsOneWidget, reason: 'a single tap must not trigger the wipe');
    expect(fixture.resetRepository.resetEverythingCallCount, 0);

    // Holding for the full duration does confirm it.
    final center = tester.getCenter(find.text('Hold to reset everything'));
    final gesture = await tester.startGesture(center);
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    await gesture.up();

    expect(tester.takeException(), isNull);
    expect(find.text('Everything has been reset. Ready for a fresh start!'), findsOneWidget);
    expect(fixture.resetRepository.resetEverythingCallCount, 1);
  });
}
