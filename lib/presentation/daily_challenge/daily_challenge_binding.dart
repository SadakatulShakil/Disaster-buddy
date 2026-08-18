import 'package:get/get.dart';

import '../../core/services/narration_service.dart';
import '../../core/services/sound_service.dart';
import '../../domain/usecases/get_todays_challenge.dart';
import '../../domain/usecases/mark_challenge_complete.dart';
import 'daily_challenge_controller.dart';

class DailyChallengeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DailyChallengeController>(
      () => DailyChallengeController(
        getTodaysChallenge: Get.find<GetTodaysChallenge>(),
        markChallengeComplete: Get.find<MarkChallengeComplete>(),
        narrationService: Get.find<NarrationService>(),
        soundService: Get.find<SoundService>(),
      ),
    );
  }
}
