import 'package:get/get.dart';

import '../../domain/usecases/get_den_state.dart';
import '../../domain/usecases/get_earned_collection.dart';
import '../../domain/usecases/get_module_progress.dart';
import '../../domain/usecases/get_modules.dart';
import '../../domain/usecases/get_todays_challenge.dart';
import 'home_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeController>(
      () => HomeController(
        getModules: Get.find<GetModules>(),
        getModuleProgress: Get.find<GetModuleProgress>(),
        getTodaysChallenge: Get.find<GetTodaysChallenge>(),
        getDenState: Get.find<GetDenState>(),
        getEarnedCollection: Get.find<GetEarnedCollection>(),
      ),
    );
  }
}
