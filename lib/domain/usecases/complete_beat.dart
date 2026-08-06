import '../../core/error/result.dart';
import '../entities/module_progress.dart';
import '../repositories/progress_repository.dart';
import 'get_module_progress.dart';

/// Marks one beat as completed and returns the module's updated progress,
/// with `isCompleted` correctly reflecting whether every beat is now done.
final class CompleteBeat {
  const CompleteBeat({
    required ProgressRepository progressRepository,
    required GetModuleProgress getModuleProgress,
  })  : _progressRepository = progressRepository,
        _getModuleProgress = getModuleProgress;

  final ProgressRepository _progressRepository;
  final GetModuleProgress _getModuleProgress;

  Future<Result<ModuleProgress>> call({
    required String moduleId,
    required String beatId,
  }) async {
    final markResult = await _progressRepository.markBeatCompleted(moduleId, beatId);
    if (markResult case Failure<void>(failure: final failure)) {
      return Failure(failure);
    }
    return _getModuleProgress(moduleId);
  }
}
