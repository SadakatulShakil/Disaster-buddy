import 'package:get/get.dart';

import '../../core/error/result.dart';
import '../../core/utils/app_logger.dart';
import '../../domain/entities/beat.dart';
import '../../domain/entities/hazard_module.dart';
import '../../domain/entities/module_progress.dart';
import '../../domain/usecases/get_module.dart';
import '../../domain/usecases/get_module_progress.dart';

/// Load state for [ModuleController], observed by ModuleHome.
enum ModuleViewStatus { loading, data, error }

/// Loads one [HazardModule] and its [ModuleProgress] by id (passed via
/// `Get.arguments`) and derives which beat the child should resume at.
class ModuleController extends GetxController {
  ModuleController({
    required GetModule getModule,
    required GetModuleProgress getModuleProgress,
    required String moduleId,
  })  : _getModule = getModule,
        _getModuleProgress = getModuleProgress,
        _moduleId = moduleId;

  final GetModule _getModule;
  final GetModuleProgress _getModuleProgress;
  final String _moduleId;

  final Rx<ModuleViewStatus> status = ModuleViewStatus.loading.obs;
  final Rx<HazardModule?> module = Rx<HazardModule?>(null);
  final Rx<ModuleProgress?> progress = Rx<ModuleProgress?>(null);
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  /// Loads the module and its progress. Exposed publicly so the UI can retry
  /// after an error.
  Future<void> load() async {
    status.value = ModuleViewStatus.loading;

    final moduleResult = await _getModule(_moduleId);
    if (moduleResult case Failure<HazardModule>(failure: final failure)) {
      AppLogger.error('ModuleController failed to load module "$_moduleId": ${failure.message}');
      errorMessage.value = failure.message;
      status.value = ModuleViewStatus.error;
      return;
    }
    module.value = (moduleResult as Success<HazardModule>).value;

    final progressResult = await _getModuleProgress(_moduleId);
    if (progressResult case Failure<ModuleProgress>(failure: final failure)) {
      AppLogger.error('ModuleController failed to load progress for "$_moduleId": ${failure.message}');
      errorMessage.value = failure.message;
      status.value = ModuleViewStatus.error;
      return;
    }
    progress.value = (progressResult as Success<ModuleProgress>).value;
    status.value = ModuleViewStatus.data;
  }

  bool isBeatCompleted(Beat beat) => progress.value?.completedBeatIds.contains(beat.id) ?? false;

  /// Index of the first incomplete beat, or the last beat if every beat is
  /// already done — there's always something to highlight as "resume here".
  int get resumeIndex {
    final beats = module.value?.beats ?? const [];
    if (beats.isEmpty) return 0;
    final firstIncomplete = beats.indexWhere((beat) => !isBeatCompleted(beat));
    return firstIncomplete == -1 ? beats.length - 1 : firstIncomplete;
  }
}
