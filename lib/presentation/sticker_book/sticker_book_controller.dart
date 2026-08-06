import 'package:get/get.dart';

import '../../core/error/result.dart';
import '../../core/utils/app_logger.dart';
import '../../domain/entities/hazard_module.dart';
import '../../domain/entities/module_progress.dart';
import '../../domain/usecases/get_module_progress.dart';
import '../../domain/usecases/get_modules.dart';

/// Load state for [StickerBookController], observed by the sticker book page.
enum StickerBookViewStatus { loading, data, error }

/// Loads every module via [GetModules] merged with real progress via
/// [GetModuleProgress], keeping only the modules whose badge has been
/// earned.
class StickerBookController extends GetxController {
  StickerBookController({
    required GetModules getModules,
    required GetModuleProgress getModuleProgress,
  })  : _getModules = getModules,
        _getModuleProgress = getModuleProgress;

  final GetModules _getModules;
  final GetModuleProgress _getModuleProgress;

  final Rx<StickerBookViewStatus> status = StickerBookViewStatus.loading.obs;
  final RxList<HazardModule> earnedModules = <HazardModule>[].obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  /// Loads earned badges. Exposed publicly so the UI can retry after an
  /// error.
  Future<void> load() async {
    status.value = StickerBookViewStatus.loading;
    final modulesResult = await _getModules();
    if (modulesResult case Failure<List<HazardModule>>(failure: final failure)) {
      AppLogger.error('StickerBookController failed to load modules: ${failure.message}');
      errorMessage.value = failure.message;
      status.value = StickerBookViewStatus.error;
      return;
    }

    final modules = (modulesResult as Success<List<HazardModule>>).value;
    final earned = <HazardModule>[];
    for (final module in modules) {
      final progressResult = await _getModuleProgress(module.id);
      if (progressResult case Success<ModuleProgress>(value: final progress)) {
        if (progress.badgeEarned) earned.add(module);
      }
    }
    earnedModules.value = earned;
    status.value = StickerBookViewStatus.data;
  }
}
