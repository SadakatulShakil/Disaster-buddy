import 'package:get/get.dart';

import '../../../core/services/narration_service.dart';
import '../../../domain/usecases/complete_activity.dart';
import '../../../domain/usecases/get_activity.dart';
import 'kit_builder_controller.dart';

class KitBuilderBinding extends Bindings {
  @override
  void dependencies() {
    final activityId = Get.arguments as String;
    Get.lazyPut<KitBuilderController>(
      () => KitBuilderController(
        getActivity: Get.find<GetActivity>(),
        completeActivity: Get.find<CompleteActivity>(),
        narrationService: Get.find<NarrationService>(),
        activityId: activityId,
      ),
    );
  }
}
