import 'package:get/get.dart';

import '../../domain/usecases/get_activities.dart';
import '../../domain/usecases/get_activity_progress.dart';
import 'activities_controller.dart';

class ActivitiesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ActivitiesController>(
      () => ActivitiesController(
        getActivities: Get.find<GetActivities>(),
        getActivityProgress: Get.find<GetActivityProgress>(),
      ),
    );
  }
}
