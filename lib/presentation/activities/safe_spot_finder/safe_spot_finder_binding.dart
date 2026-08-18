import 'package:get/get.dart';

import '../../../core/services/narration_service.dart';
import '../../../core/services/sound_service.dart';
import '../../../domain/usecases/complete_activity.dart';
import '../../../domain/usecases/get_activity.dart';
import 'safe_spot_finder_controller.dart';

class SafeSpotFinderBinding extends Bindings {
  @override
  void dependencies() {
    final activityId = Get.arguments as String;
    Get.lazyPut<SafeSpotFinderController>(
      () => SafeSpotFinderController(
        getActivity: Get.find<GetActivity>(),
        completeActivity: Get.find<CompleteActivity>(),
        narrationService: Get.find<NarrationService>(),
        soundService: Get.find<SoundService>(),
        activityId: activityId,
      ),
    );
  }
}
