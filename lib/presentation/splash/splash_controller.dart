import 'package:get/get.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/user_pref_service.dart';
import '../../core/theme/app_durations.dart';

class SplashController extends GetxController {
  final _pref = UserPrefService.instance;

  @override
  void onReady() {
    super.onReady();
    _decideNext();
  }

  Future<void> _decideNext() async {
    // Small delay so the mascot splash is visible.
    await Future.delayed(AppDurations.splashHold);

    // First run OR no language chosen yet -> language picker.
    if (_pref.isFirstRun || _pref.languageCode == null) {
      Get.offAllNamed(AppRoutes.language);
    } else {
      Get.offAllNamed(AppRoutes.home);
    }
  }
}
