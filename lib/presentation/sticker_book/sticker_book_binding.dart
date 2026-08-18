import 'package:get/get.dart';

import '../../domain/usecases/get_earned_collection.dart';
import 'sticker_book_controller.dart';

class StickerBookBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<StickerBookController>(
      () => StickerBookController(getEarnedCollection: Get.find<GetEarnedCollection>()),
    );
  }
}
