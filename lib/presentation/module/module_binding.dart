import 'package:get/get.dart';

import '../../domain/usecases/get_module.dart';
import '../../domain/usecases/get_module_progress.dart';
import 'module_controller.dart';

class ModuleBinding extends Bindings {
  @override
  void dependencies() {
    final moduleId = Get.arguments as String;
    Get.lazyPut<ModuleController>(
      () => ModuleController(
        getModule: Get.find<GetModule>(),
        getModuleProgress: Get.find<GetModuleProgress>(),
        moduleId: moduleId,
      ),
    );
  }
}
