import 'package:get/get.dart';

import '../../../core/services/narration_service.dart';
import '../../../core/services/sound_service.dart';
import '../../../domain/usecases/complete_activity.dart';
import '../../../domain/usecases/get_activity.dart';
import 'read_the_sky_controller.dart';

class ReadTheSkyBinding extends Bindings {
  @override
  void dependencies() {
    final activityId = Get.arguments as String;
    Get.lazyPut<ReadTheSkyController>(
      () => ReadTheSkyController(
        getActivity: Get.find<GetActivity>(),
        completeActivity: Get.find<CompleteActivity>(),
        narrationService: Get.find<NarrationService>(),
        soundService: Get.find<SoundService>(),
        activityId: activityId,
      ),
    );
  }
}
