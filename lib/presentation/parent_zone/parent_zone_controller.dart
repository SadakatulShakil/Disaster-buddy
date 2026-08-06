import 'package:get/get.dart';

import '../../core/error/result.dart';
import '../../core/utils/app_logger.dart';
import '../../domain/entities/activity.dart';
import '../../domain/entities/activity_progress.dart';
import '../../domain/entities/hazard_module.dart';
import '../../domain/entities/module_progress.dart';
import '../../domain/usecases/get_activities.dart';
import '../../domain/usecases/get_activity_progress.dart';
import '../../domain/usecases/get_module_progress.dart';
import '../../domain/usecases/get_modules.dart';
import '../../domain/usecases/reset_everything.dart';
import '../../domain/usecases/reset_learning_progress.dart';
import '../../domain/usecases/reset_single_module.dart';
import '../den/den_controller.dart';
import '../home/home_controller.dart';
import '../sticker_book/sticker_book_controller.dart';

/// Load state for [ParentZoneController], observed by the parent zone page.
enum ParentZoneViewStatus { loading, data, error }

/// Builds the real progress-summary numbers shown in the Parent Zone by
/// combining [GetModules]/[GetActivities] with their progress use cases —
/// no new persistence, just a different view over the same progress data
/// used by the Adventure Map and Activities screens. Also orchestrates the
/// parent-controlled resets: applies the chosen reset, reloads its own
/// summary, and refreshes any currently-live child-facing controllers so
/// nothing shows stale data after the parent returns to the child UI.
class ParentZoneController extends GetxController {
  ParentZoneController({
    required GetModules getModules,
    required GetModuleProgress getModuleProgress,
    required GetActivities getActivities,
    required GetActivityProgress getActivityProgress,
    required ResetLearningProgress resetLearningProgress,
    required ResetSingleModule resetSingleModule,
    required ResetEverything resetEverything,
  })  : _getModules = getModules,
        _getModuleProgress = getModuleProgress,
        _getActivities = getActivities,
        _getActivityProgress = getActivityProgress,
        _resetLearningProgress = resetLearningProgress,
        _resetSingleModule = resetSingleModule,
        _resetEverything = resetEverything;

  final GetModules _getModules;
  final GetModuleProgress _getModuleProgress;
  final GetActivities _getActivities;
  final GetActivityProgress _getActivityProgress;
  final ResetLearningProgress _resetLearningProgress;
  final ResetSingleModule _resetSingleModule;
  final ResetEverything _resetEverything;

  final Rx<ParentZoneViewStatus> status = ParentZoneViewStatus.loading.obs;
  final RxInt totalModules = 0.obs;
  final RxInt completedModules = 0.obs;
  final RxInt totalActivities = 0.obs;
  final RxInt completedActivities = 0.obs;
  final RxInt badgesEarned = 0.obs;
  final RxString errorMessage = ''.obs;

  /// Every hazard module, for the "reset one hazard" picker.
  final RxList<HazardModule> modules = <HazardModule>[].obs;

  /// Ids of modules currently completed, so the picker can show each
  /// module's real state rather than guessing.
  final RxSet<String> completedModuleIds = <String>{}.obs;

  /// True while a reset is being applied — the UI disables the reset
  /// options rather than allowing a second tap mid-reset.
  final RxBool isResetting = false.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  /// Loads the progress summary. Exposed publicly so the UI can retry after
  /// an error.
  Future<void> load() async {
    status.value = ParentZoneViewStatus.loading;
    final modulesResult = await _getModules();
    if (modulesResult case Failure<List<HazardModule>>(failure: final failure)) {
      AppLogger.error('ParentZoneController failed to load modules: ${failure.message}');
      errorMessage.value = failure.message;
      status.value = ParentZoneViewStatus.error;
      return;
    }

    final loadedModules = (modulesResult as Success<List<HazardModule>>).value;
    var completed = 0;
    var badges = 0;
    final completedIds = <String>{};
    for (final module in loadedModules) {
      final progressResult = await _getModuleProgress(module.id);
      if (progressResult case Success<ModuleProgress>(value: final progress)) {
        if (progress.isCompleted) {
          completed++;
          completedIds.add(module.id);
        }
        if (progress.badgeEarned) badges++;
      }
    }
    modules.value = loadedModules;
    completedModuleIds.assignAll(completedIds);

    final activitiesResult = await _getActivities();
    var activityCount = 0;
    var completedActivityCount = 0;
    switch (activitiesResult) {
      case Success<List<Activity>>(value: final activities):
        activityCount = activities.length;
        for (final activity in activities) {
          final progressResult = await _getActivityProgress(activity.id);
          if (progressResult case Success<ActivityProgress>(value: final progress)) {
            if (progress.isCompleted) completedActivityCount++;
            if (progress.badgeEarned) badges++;
          }
        }
      case Failure<List<Activity>>(failure: final failure):
        // Activities are supplementary to the summary — log and keep
        // showing the module numbers rather than failing the whole screen.
        AppLogger.error('ParentZoneController failed to load activities: ${failure.message}');
    }

    totalModules.value = modules.length;
    completedModules.value = completed;
    totalActivities.value = activityCount;
    completedActivities.value = completedActivityCount;
    badgesEarned.value = badges;
    status.value = ParentZoneViewStatus.data;
  }

  /// Clears all module/activity progress, quiz results, and their badges.
  /// On success, reloads this screen's summary and refreshes any
  /// currently-live child-facing controllers.
  Future<Result<void>> performResetLearningProgress() => _performReset(_resetLearningProgress.call);

  /// Clears one hazard module's progress, quiz results, and badge.
  Future<Result<void>> performResetSingleModule(String moduleId) =>
      _performReset(() => _resetSingleModule(moduleId));

  /// Wipes every progress/engagement table for a brand-new start.
  Future<Result<void>> performResetEverything() => _performReset(_resetEverything.call);

  Future<Result<void>> _performReset(Future<Result<void>> Function() reset) async {
    isResetting.value = true;
    final result = await reset();
    if (result is Success<void>) {
      await load();
      _refreshChildFacingControllers();
    }
    isResetting.value = false;
    return result;
  }

  /// Home/Den/StickerBook are only re-created (and so only reload) when
  /// their page is next pushed — but a parent can reach this screen
  /// without popping the Adventure Map underneath, so any currently-live
  /// instance needs an explicit nudge to avoid showing stale progress.
  void _refreshChildFacingControllers() {
    if (Get.isRegistered<HomeController>()) {
      Get.find<HomeController>().refreshAll();
    }
    if (Get.isRegistered<DenController>()) {
      Get.find<DenController>().load();
    }
    if (Get.isRegistered<StickerBookController>()) {
      Get.find<StickerBookController>().load();
    }
  }
}
