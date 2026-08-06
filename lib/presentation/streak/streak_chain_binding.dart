import 'package:get/get.dart';

import '../../domain/usecases/get_streak_overview.dart';
import 'streak_chain_controller.dart';

class StreakChainBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<StreakChainController>(
      () => StreakChainController(getStreakOverview: Get.find<GetStreakOverview>()),
    );
  }
}
