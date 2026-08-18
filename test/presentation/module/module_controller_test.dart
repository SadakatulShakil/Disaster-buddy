// UX pass: ModuleHome must reflect a beat's completed state and the next
// incomplete beat as "resume here" the moment it reloads — this is what
// lets returning from a finished beat (Part A's flow fix) show fresh state
// without an app restart, since ModulePage already awaits the lesson route
// and calls `controller.load()` again on return.

import 'package:flutter_test/flutter_test.dart';

import 'package:bipod_bondhu/domain/entities/badge_info.dart';
import 'package:bipod_bondhu/domain/entities/beat.dart';
import 'package:bipod_bondhu/domain/entities/hazard_module.dart';
import 'package:bipod_bondhu/domain/entities/localized_text.dart';
import 'package:bipod_bondhu/domain/usecases/get_module.dart';
import 'package:bipod_bondhu/domain/usecases/get_module_progress.dart';
import 'package:bipod_bondhu/presentation/module/module_controller.dart';

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

void main() {
  test('with nothing completed, the first beat is the resume target and nothing shows completed', () async {
    final contentRepository = FakeContentRepository([_twoBeatModule()]);
    final progressRepository = FakeProgressRepository();
    final controller = ModuleController(
      getModule: GetModule(contentRepository),
      getModuleProgress: GetModuleProgress(contentRepository: contentRepository, progressRepository: progressRepository),
      moduleId: 'earthquake',
    );

    await controller.load();

    final beats = controller.module.value!.beats;
    expect(controller.resumeIndex, 0);
    expect(controller.isBeatCompleted(beats[0]), isFalse);
    expect(controller.isBeatCompleted(beats[1]), isFalse);
  });

  test('reloading after a beat is completed elsewhere shows it done and highlights the next one', () async {
    final contentRepository = FakeContentRepository([_twoBeatModule()]);
    final progressRepository = FakeProgressRepository();
    final controller = ModuleController(
      getModule: GetModule(contentRepository),
      getModuleProgress: GetModuleProgress(contentRepository: contentRepository, progressRepository: progressRepository),
      moduleId: 'earthquake',
    );
    await controller.load();
    final beats = controller.module.value!.beats;
    expect(controller.resumeIndex, 0);

    // Simulates what `LessonController.completeCurrentBeat()` persisted
    // while ModuleHome was off-screen — mirrors the awaited
    // `Get.toNamed(...); controller.load();` round trip in `_openBeat`.
    await progressRepository.markBeatCompleted('earthquake', 'beat_1');
    await controller.load();

    expect(controller.isBeatCompleted(beats[0]), isTrue);
    expect(controller.isBeatCompleted(beats[1]), isFalse);
    expect(controller.resumeIndex, 1);
  });

  test('once every beat is completed, the last beat stays the (replayable) highlight', () async {
    final contentRepository = FakeContentRepository([_twoBeatModule()]);
    final progressRepository = FakeProgressRepository();
    final controller = ModuleController(
      getModule: GetModule(contentRepository),
      getModuleProgress: GetModuleProgress(contentRepository: contentRepository, progressRepository: progressRepository),
      moduleId: 'earthquake',
    );

    await progressRepository.markBeatCompleted('earthquake', 'beat_1');
    await progressRepository.markBeatCompleted('earthquake', 'beat_2');
    await controller.load();

    final beats = controller.module.value!.beats;
    expect(controller.isBeatCompleted(beats[0]), isTrue);
    expect(controller.isBeatCompleted(beats[1]), isTrue);
    expect(controller.resumeIndex, 1);
  });
}
