import 'package:get/get.dart';

import '../../core/error/result.dart';
import '../../core/utils/app_logger.dart';
import '../../domain/usecases/get_streak_overview.dart';

/// Load state for [StreakChainController], observed by [StreakChainPage].
enum StreakChainViewStatus { loading, data, error }

/// Loads the streak counters plus the rendered day-by-day chain for the
/// streak chain view.
class StreakChainController extends GetxController {
  StreakChainController({required GetStreakOverview getStreakOverview}) : _getStreakOverview = getStreakOverview;

  final GetStreakOverview _getStreakOverview;

  final Rx<StreakChainViewStatus> status = StreakChainViewStatus.loading.obs;
  final Rx<StreakOverview?> overview = Rx<StreakOverview?>(null);
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  /// Exposed publicly so the UI can retry after an error.
  Future<void> load() async {
    status.value = StreakChainViewStatus.loading;
    final result = await _getStreakOverview();
    switch (result) {
      case Success<StreakOverview>(value: final data):
        overview.value = data;
        status.value = StreakChainViewStatus.data;
      case Failure<StreakOverview>(failure: final failure):
        AppLogger.error('StreakChainController failed to load: ${failure.message}');
        errorMessage.value = failure.message;
        status.value = StreakChainViewStatus.error;
    }
  }
}
