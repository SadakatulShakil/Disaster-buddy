import 'package:get/get.dart';

import '../../core/error/result.dart';
import '../../core/utils/app_logger.dart';
import '../../domain/entities/activity.dart';
import '../../domain/entities/activity_progress.dart';
import '../../domain/usecases/get_activities.dart';
import '../../domain/usecases/get_activity_progress.dart';

/// Load state for [ActivitiesController], observed by the Activities page.
enum ActivitiesViewStatus { loading, data, error }

/// Loads every implemented cross-cutting activity via [GetActivities]
/// merged with real progress via [GetActivityProgress] — the same
/// content-plus-progress shape [HomeController] uses for modules.
class ActivitiesController extends GetxController {
  ActivitiesController({
    required GetActivities getActivities,
    required GetActivityProgress getActivityProgress,
  })  : _getActivities = getActivities,
        _getActivityProgress = getActivityProgress;

  final GetActivities _getActivities;
  final GetActivityProgress _getActivityProgress;

  final Rx<ActivitiesViewStatus> status = ActivitiesViewStatus.loading.obs;
  final RxList<Activity> activities = <Activity>[].obs;
  final RxMap<String, ActivityProgress> progressByActivity = <String, ActivityProgress>{}.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  /// Loads all activities, then their progress. Exposed publicly so the UI
  /// can retry after an error.
  Future<void> load() async {
    status.value = ActivitiesViewStatus.loading;
    final result = await _getActivities();
    switch (result) {
      case Success<List<Activity>>(value: final loadedActivities):
        activities.value = loadedActivities;
        await _loadProgress(loadedActivities);
        status.value = ActivitiesViewStatus.data;
      case Failure<List<Activity>>(failure: final failure):
        AppLogger.error('ActivitiesController failed to load activities: ${failure.message}');
        errorMessage.value = failure.message;
        status.value = ActivitiesViewStatus.error;
    }
  }

  Future<void> _loadProgress(List<Activity> loadedActivities) async {
    for (final activity in loadedActivities) {
      final result = await _getActivityProgress(activity.id);
      if (result case Success<ActivityProgress>(value: final progress)) {
        progressByActivity[activity.id] = progress;
      }
    }
  }

  bool isActivityCompleted(String activityId) => progressByActivity[activityId]?.isCompleted ?? false;
}
