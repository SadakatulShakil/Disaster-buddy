import 'package:get/get.dart';

import '../../core/services/narration_service.dart';
import '../../domain/usecases/get_den_state.dart';
import '../../domain/usecases/get_earned_collection.dart';
import '../../domain/usecases/get_streak_overview.dart';
import '../../domain/usecases/get_todays_challenge.dart';
import '../../domain/usecases/place_sticker.dart';
import '../../domain/usecases/remove_sticker.dart';
import '../../domain/usecases/set_den_theme.dart';
import 'den_controller.dart';

class DenBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DenController>(
      () => DenController(
        getDenState: Get.find<GetDenState>(),
        getEarnedCollection: Get.find<GetEarnedCollection>(),
        getStreakOverview: Get.find<GetStreakOverview>(),
        getTodaysChallenge: Get.find<GetTodaysChallenge>(),
        placeSticker: Get.find<PlaceSticker>(),
        removeSticker: Get.find<RemoveSticker>(),
        setDenTheme: Get.find<SetDenTheme>(),
        narrationService: Get.find<NarrationService>(),
      ),
    );
  }
}
