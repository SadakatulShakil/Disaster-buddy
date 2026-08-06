import 'package:get/get.dart';

import '../../core/error/result.dart';
import '../../core/utils/app_logger.dart';
import '../../domain/entities/collectible_sticker.dart';
import '../../domain/entities/den_state.dart';
import '../../domain/entities/hazard_module.dart';
import '../../domain/entities/module_progress.dart';
import '../../domain/usecases/get_den_state.dart';
import '../../domain/usecases/get_earned_collection.dart';
import '../../domain/usecases/get_module_progress.dart';
import '../../domain/usecases/get_modules.dart';
import '../../domain/usecases/get_todays_challenge.dart';

/// Load state for [HomeController], observed by the home page.
enum HomeViewStatus { loading, data, error }

/// A module stop's state on the adventure map.
enum ModuleStopState {
  /// Unlocked and not yet finished — the child can tap it now.
  available,

  /// Every beat in the module is done.
  completed,

  /// Not yet unlocked; shown as a calm "coming next" state, never an error.
  locked,
}

/// Loads every hazard module via [GetModules] merged with real progress via
/// [GetModuleProgress], and derives each module's [ModuleStopState] for the
/// Adventure Map: module 0 is always available; module `n` unlocks once
/// module `n - 1` is completed.
class HomeController extends GetxController {
  HomeController({
    required GetModules getModules,
    required GetModuleProgress getModuleProgress,
    required GetTodaysChallenge getTodaysChallenge,
    required GetDenState getDenState,
    required GetEarnedCollection getEarnedCollection,
  })  : _getModules = getModules,
        _getModuleProgress = getModuleProgress,
        _getTodaysChallenge = getTodaysChallenge,
        _getDenState = getDenState,
        _getEarnedCollection = getEarnedCollection;

  final GetModules _getModules;
  final GetModuleProgress _getModuleProgress;
  final GetTodaysChallenge _getTodaysChallenge;
  final GetDenState _getDenState;
  final GetEarnedCollection _getEarnedCollection;

  final Rx<HomeViewStatus> status = HomeViewStatus.loading.obs;
  final RxList<HazardModule> modules = <HazardModule>[].obs;
  final RxMap<String, ModuleProgress> progressByModule = <String, ModuleProgress>{}.obs;
  final RxString errorMessage = ''.obs;

  /// The daily-challenge card's data, or null while it loads or if it
  /// failed — a failure here is silent (see [_loadDailyChallengeSummary]),
  /// so the Adventure Map itself is never blocked by it.
  final Rx<TodaysChallengeResult?> dailyChallengeSummary = Rx<TodaysChallengeResult?>(null);

  /// Whether Tuku's Den has an earned sticker still waiting to be placed —
  /// shown as a small indicator on the Den entry point. Never blocks the
  /// Adventure Map if it fails to load (see [_loadDenIndicator]).
  final RxBool hasUnplacedSticker = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadModules();
    _loadDailyChallengeSummary();
    _loadDenIndicator();
  }

  /// Reloads every piece of this screen's state — modules/progress, the
  /// daily-challenge card, and the Den indicator. Used when something
  /// outside the normal page lifecycle (a parent-controlled progress
  /// reset) may have changed the data while this controller stayed alive.
  Future<void> refreshAll() async {
    await loadModules();
    await _loadDailyChallengeSummary();
    await _loadDenIndicator();
  }

  /// Loads all modules, then their progress. Exposed publicly so the UI can
  /// retry after an error.
  Future<void> loadModules() async {
    status.value = HomeViewStatus.loading;
    final result = await _getModules();
    switch (result) {
      case Success<List<HazardModule>>(value: final loadedModules):
        modules.value = loadedModules;
        await _loadProgress(loadedModules);
        status.value = HomeViewStatus.data;
      case Failure<List<HazardModule>>(failure: final failure):
        AppLogger.error('HomeController failed to load modules: ${failure.message}');
        errorMessage.value = failure.message;
        status.value = HomeViewStatus.error;
    }
  }

  Future<void> _loadProgress(List<HazardModule> loadedModules) async {
    for (final module in loadedModules) {
      final result = await _getModuleProgress(module.id);
      if (result case Success<ModuleProgress>(value: final progress)) {
        progressByModule[module.id] = progress;
      }
    }
  }

  /// A nice-to-have, not a blocker: the daily-challenge card simply doesn't
  /// render if this fails, rather than surfacing an error over the whole
  /// Adventure Map.
  Future<void> _loadDailyChallengeSummary() async {
    final result = await _getTodaysChallenge();
    switch (result) {
      case Success<TodaysChallengeResult>(value: final data):
        dailyChallengeSummary.value = data;
      case Failure<TodaysChallengeResult>(failure: final failure):
        AppLogger.error('HomeController failed to load daily challenge summary: ${failure.message}');
    }
  }

  /// A nice-to-have, not a blocker: the Den indicator simply doesn't show
  /// if this fails, rather than surfacing an error over the whole
  /// Adventure Map.
  Future<void> _loadDenIndicator() async {
    final denResult = await _getDenState();
    final collectionResult = await _getEarnedCollection();
    if (denResult is! Success<DenState> || collectionResult is! Success<List<CollectibleSticker>>) {
      if (denResult case Failure<DenState>(failure: final failure)) {
        AppLogger.error('HomeController failed to load Den indicator: ${failure.message}');
      }
      return;
    }

    final placedIds =
        denResult.value.slots.map((slot) => slot.placedStickerId).whereType<String>().toSet();
    hasUnplacedSticker.value =
        collectionResult.value.any((sticker) => sticker.earned && !placedIds.contains(sticker.badge.id));
  }

  bool isModuleCompleted(String moduleId) => progressByModule[moduleId]?.isCompleted ?? false;

  /// The adventure-map state of the module at [index], derived from real
  /// progress: always available at index 0, otherwise available only once
  /// the previous module is completed.
  ModuleStopState stateFor(int index) {
    final module = modules[index];
    if (isModuleCompleted(module.id)) return ModuleStopState.completed;
    if (index == 0) return ModuleStopState.available;
    final previousModule = modules[index - 1];
    return isModuleCompleted(previousModule.id) ? ModuleStopState.available : ModuleStopState.locked;
  }
}
