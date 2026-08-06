import '../../core/error/result.dart';
import '../entities/hazard_module.dart';
import '../entities/module_progress.dart';
import '../repositories/content_repository.dart';
import '../repositories/progress_repository.dart';

/// Builds a [ModuleProgress] snapshot for one module by combining its
/// persisted progress with its static beat list, so `isCompleted` is always
/// derived rather than duplicated into the database.
final class GetModuleProgress {
  const GetModuleProgress({
    required ContentRepository contentRepository,
    required ProgressRepository progressRepository,
  })  : _contentRepository = contentRepository,
        _progressRepository = progressRepository;

  final ContentRepository _contentRepository;
  final ProgressRepository _progressRepository;

  Future<Result<ModuleProgress>> call(String moduleId) async {
    final moduleResult = await _contentRepository.getModule(moduleId);
    if (moduleResult case Failure<HazardModule>(failure: final failure)) {
      return Failure(failure);
    }
    final module = (moduleResult as Success<HazardModule>).value;

    final completedResult = await _progressRepository.getCompletedBeatIds(moduleId);
    if (completedResult case Failure<Set<String>>(failure: final failure)) {
      return Failure(failure);
    }
    final completedBeatIds = (completedResult as Success<Set<String>>).value;

    final badgeResult = await _progressRepository.hasBadge(moduleId, module.badge.id);
    final badgeEarned = badgeResult is Success<bool> ? badgeResult.value : false;

    final isCompleted = module.beats.every((beat) => completedBeatIds.contains(beat.id));

    return Success(
      ModuleProgress(
        moduleId: moduleId,
        completedBeatIds: completedBeatIds,
        isCompleted: isCompleted,
        badgeEarned: badgeEarned,
      ),
    );
  }
}
