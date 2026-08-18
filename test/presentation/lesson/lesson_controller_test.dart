// UX pass: completing a beat always returns to ModuleHome — never
// auto-advances to the next beat — except the one time it makes the module
// newly fully-complete, when it awards the badge once and routes to the
// reward celebration instead. Completion is order-independent: the module
// completes whenever its last remaining beat is finished, in whatever order
// the child chooses. Reviewing an already-completed beat never re-awards.

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
import 'package:bipod_bondhu/domain/entities/badge_info.dart';
import 'package:bipod_bondhu/domain/entities/beat.dart';
import 'package:bipod_bondhu/domain/entities/hazard_module.dart';
import 'package:bipod_bondhu/domain/entities/localized_text.dart';
import 'package:bipod_bondhu/domain/usecases/award_badge.dart';
import 'package:bipod_bondhu/domain/usecases/complete_beat.dart';
import 'package:bipod_bondhu/domain/usecases/get_module.dart';
import 'package:bipod_bondhu/domain/usecases/get_module_progress.dart';
import 'package:bipod_bondhu/domain/usecases/save_quiz_result.dart';
import 'package:bipod_bondhu/presentation/lesson/lesson_controller.dart';

import '../../fakes/fake_content_repository.dart';
import '../../fakes/fake_flutter_tts.dart';
import '../../fakes/fake_progress_repository.dart';

const _text = LocalizedText(bn: 'ক', en: 'a');

HazardModule _twoBeatModule() => const HazardModule(
      id: 'earthquake',
      order: 1,
      title: _text,
      themeColorHex: '#A0522D',
      iconAsset: 'icon.png',
      safeAction: _text,
      badge: BadgeInfo(id: 'earthquake_badge', title: _text, iconAsset: 'badge.png'),
      beats: [
        StoryBeat(id: 'beat_1', order: 1, slides: []),
        StepsBeat(id: 'beat_2', order: 2, slides: []),
      ],
    );

LessonController _buildController({
  required FakeContentRepository contentRepository,
  required FakeProgressRepository progressRepository,
  required String startBeatId,
}) {
  final getModuleProgress = GetModuleProgress(
    contentRepository: contentRepository,
    progressRepository: progressRepository,
  );
  return LessonController(
    getModule: GetModule(contentRepository),
    completeBeat: CompleteBeat(progressRepository: progressRepository, getModuleProgress: getModuleProgress),
    awardBadge: AwardBadge(progressRepository),
    saveQuizResult: SaveQuizResult(progressRepository),
    narrationService: NarrationService(tts: FakeFlutterTts()),
    soundService: SoundService(),
    moduleId: 'earthquake',
    startBeatId: startBeatId,
  );
}

/// A minimal GetMaterialApp so the controller's `Get.back()`/`Get.offNamed`
/// navigation calls have somewhere to act instead of throwing.
Widget _wrap() {
  return ScreenUtilInit(
    designSize: AppConstants.designSize,
    builder: (context, child) => GetMaterialApp(
      translations: AppTranslations(),
      locale: const Locale('en', 'US'),
      initialRoute: '/home',
      getPages: [
        GetPage(name: '/home', page: () => const SizedBox()),
        GetPage(name: '/lesson', page: () => const SizedBox()),
        GetPage(name: '/reward', page: () => const SizedBox()),
      ],
    ),
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await UserPrefService.instance.init();
  });
  tearDown(Get.reset);

  testWidgets('completing a non-final beat returns to ModuleHome — no auto-advance', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    Get.toNamed('/lesson');
    await tester.pumpAndSettle();

    final contentRepository = FakeContentRepository([_twoBeatModule()]);
    final progressRepository = FakeProgressRepository();
    final controller = _buildController(
      contentRepository: contentRepository,
      progressRepository: progressRepository,
      startBeatId: 'beat_1',
    );
    await controller.load();

    await controller.completeCurrentBeat();
    await tester.pumpAndSettle();

    // The lesson never walks forward to beat_2 by itself.
    expect(controller.currentBeatIndex.value, 0);
    expect(progressRepository.awardBadgeCallCount, 0);
    expect(Get.currentRoute, '/home');
  });

  testWidgets('completing the last remaining beat awards the badge once and routes to reward', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    Get.toNamed('/lesson');
    await tester.pumpAndSettle();

    final contentRepository = FakeContentRepository([_twoBeatModule()]);
    final progressRepository = FakeProgressRepository()..completedBeatIdsByModule['earthquake'] = {'beat_1'};
    final controller = _buildController(
      contentRepository: contentRepository,
      progressRepository: progressRepository,
      startBeatId: 'beat_2',
    );
    await controller.load();

    await controller.completeCurrentBeat();
    await tester.pumpAndSettle();

    expect(progressRepository.awardBadgeCallCount, 1);
    expect(progressRepository.earnedBadgeIds, {'earthquake_badge'});
    expect(Get.currentRoute, '/reward');
  });

  testWidgets('module completion is order-independent — finishing beat_2 first, then beat_1, still completes it',
      (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    Get.toNamed('/lesson');
    await tester.pumpAndSettle();

    final contentRepository = FakeContentRepository([_twoBeatModule()]);
    final progressRepository = FakeProgressRepository();
    final firstController = _buildController(
      contentRepository: contentRepository,
      progressRepository: progressRepository,
      startBeatId: 'beat_2',
    );
    await firstController.load();
    await firstController.completeCurrentBeat();
    await tester.pumpAndSettle();

    expect(progressRepository.awardBadgeCallCount, 0);
    expect(Get.currentRoute, '/home');

    Get.toNamed('/lesson');
    await tester.pumpAndSettle();
    final secondController = _buildController(
      contentRepository: contentRepository,
      progressRepository: progressRepository,
      startBeatId: 'beat_1',
    );
    await secondController.load();
    await secondController.completeCurrentBeat();
    await tester.pumpAndSettle();

    expect(progressRepository.awardBadgeCallCount, 1);
    expect(progressRepository.earnedBadgeIds, {'earthquake_badge'});
    expect(Get.currentRoute, '/reward');
  });

  testWidgets('reviewing an already-completed beat does not re-award', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    Get.toNamed('/lesson');
    await tester.pumpAndSettle();

    final contentRepository = FakeContentRepository([_twoBeatModule()]);
    final progressRepository = FakeProgressRepository()
      ..completedBeatIdsByModule['earthquake'] = {'beat_1', 'beat_2'}
      ..earnedBadgeIds.add('earthquake_badge');

    final controller = _buildController(
      contentRepository: contentRepository,
      progressRepository: progressRepository,
      startBeatId: 'beat_2',
    );
    await controller.load();

    await controller.completeCurrentBeat();
    await tester.pumpAndSettle();

    expect(progressRepository.awardBadgeCallCount, 0);
    expect(progressRepository.earnedBadgeIds, {'earthquake_badge'});
    expect(Get.currentRoute, '/home');
  });
}
