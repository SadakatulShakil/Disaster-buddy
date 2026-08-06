// Phase 3: completing a module's final beat must mark it complete and award
// its badge exactly once; replaying an already-completed beat must never
// re-award it.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:bipod_bondhu/core/constants/app_constants.dart';
import 'package:bipod_bondhu/core/localization/app_translations.dart';
import 'package:bipod_bondhu/core/services/narration_service.dart';
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
  required bool isReplay,
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
    narrationService: NarrationService(),
    moduleId: 'earthquake',
    startBeatId: startBeatId,
    isReplay: isReplay,
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
  tearDown(Get.reset);

  testWidgets('completing the final beat marks the module complete and awards the badge once', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    // Not awaited: `Get.toNamed`'s future only resolves once this route is
    // later popped, which this test never does — awaiting it would hang.
    Get.toNamed('/lesson');
    await tester.pumpAndSettle();

    final contentRepository = FakeContentRepository([_twoBeatModule()]);
    final progressRepository = FakeProgressRepository();
    final controller = _buildController(
      contentRepository: contentRepository,
      progressRepository: progressRepository,
      startBeatId: 'beat_1',
      isReplay: false,
    );
    await controller.load();

    await controller.completeCurrentBeat(); // beat_1: not the last beat -> advance
    expect(controller.currentBeatIndex.value, 1);
    expect(progressRepository.awardBadgeCallCount, 0);

    await controller.completeCurrentBeat(); // beat_2: last beat -> completes + awards
    expect(progressRepository.awardBadgeCallCount, 1);
    expect(progressRepository.earnedBadgeIds, {'earthquake_badge'});
  });

  testWidgets('replaying a completed beat does not double-award', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    // Not awaited: `Get.toNamed`'s future only resolves once this route is
    // later popped, which this test never does — awaiting it would hang.
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
      isReplay: true,
    );
    await controller.load();
    expect(controller.currentBeatIndex.value, 1);

    await controller.completeCurrentBeat(); // replay of the (already completed) last beat

    expect(progressRepository.awardBadgeCallCount, 0);
    expect(progressRepository.earnedBadgeIds, {'earthquake_badge'});
  });
}
