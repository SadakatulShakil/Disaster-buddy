import 'package:get/get.dart';

import '../../domain/usecases/get_activities.dart';
import '../../domain/usecases/get_activity_progress.dart';
import '../../domain/usecases/get_module_progress.dart';
import '../../domain/usecases/get_modules.dart';
import '../../domain/usecases/reset_everything.dart';
import '../../domain/usecases/reset_learning_progress.dart';
import '../../domain/usecases/reset_single_module.dart';
import 'parent_zone_controller.dart';

class ParentZoneBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ParentZoneController>(
      () => ParentZoneController(
        getModules: Get.find<GetModules>(),
        getModuleProgress: Get.find<GetModuleProgress>(),
        getActivities: Get.find<GetActivities>(),
        getActivityProgress: Get.find<GetActivityProgress>(),
        resetLearningProgress: Get.find<ResetLearningProgress>(),
        resetSingleModule: Get.find<ResetSingleModule>(),
        resetEverything: Get.find<ResetEverything>(),
      ),
    );
  }
}
