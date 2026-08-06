import 'package:get/get.dart';

import '../../domain/usecases/get_module_progress.dart';
import '../../domain/usecases/get_modules.dart';
import 'sticker_book_controller.dart';

class StickerBookBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<StickerBookController>(
      () => StickerBookController(
        getModules: Get.find<GetModules>(),
        getModuleProgress: Get.find<GetModuleProgress>(),
      ),
    );
  }
}
