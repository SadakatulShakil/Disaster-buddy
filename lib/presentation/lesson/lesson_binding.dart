import 'package:get/get.dart';

import '../../core/services/narration_service.dart';
import '../../domain/usecases/award_badge.dart';
import '../../domain/usecases/complete_beat.dart';
import '../../domain/usecases/get_module.dart';
import '../../domain/usecases/save_quiz_result.dart';
import 'lesson_args.dart';
import 'lesson_controller.dart';

class LessonBinding extends Bindings {
  @override
  void dependencies() {
    final args = Get.arguments as LessonArgs;
    Get.lazyPut<LessonController>(
      () => LessonController(
        getModule: Get.find<GetModule>(),
        completeBeat: Get.find<CompleteBeat>(),
        awardBadge: Get.find<AwardBadge>(),
        saveQuizResult: Get.find<SaveQuizResult>(),
        narrationService: Get.find<NarrationService>(),
        moduleId: args.moduleId,
        startBeatId: args.startBeatId,
        isReplay: args.isReplay,
      ),
    );
  }
}
