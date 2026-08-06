import '../../core/error/result.dart';
import '../entities/activity.dart';
import '../entities/activity_progress.dart';
import '../repositories/activity_progress_repository.dart';
import '../repositories/activity_repository.dart';
import '../repositories/progress_repository.dart';

/// Builds an [ActivityProgress] snapshot for one activity by combining its
/// persisted completion flag with its badge-earned state — mirrors
/// [GetModuleProgress]'s shape for modules.
final class GetActivityProgress {
  const GetActivityProgress({
    required ActivityRepository activityRepository,
    required ActivityProgressRepository activityProgressRepository,
    required ProgressRepository progressRepository,
  })  : _activityRepository = activityRepository,
        _activityProgressRepository = activityProgressRepository,
        _progressRepository = progressRepository;

  final ActivityRepository _activityRepository;
  final ActivityProgressRepository _activityProgressRepository;
  final ProgressRepository _progressRepository;

  Future<Result<ActivityProgress>> call(String activityId) async {
    final activityResult = await _activityRepository.getActivity(activityId);
    if (activityResult case Failure<Activity>(failure: final failure)) {
      return Failure(failure);
    }
    final activity = (activityResult as Success<Activity>).value;

    final completedResult = await _activityProgressRepository.isActivityCompleted(activityId);
    if (completedResult case Failure<bool>(failure: final failure)) {
      return Failure(failure);
    }
    final isCompleted = (completedResult as Success<bool>).value;

    var badgeEarned = false;
    final badge = activity.badge;
    if (badge != null) {
      final badgeResult = await _progressRepository.hasBadge(activityId, badge.id);
      badgeEarned = badgeResult is Success<bool> ? badgeResult.value : false;
    }

    return Success(ActivityProgress(activityId: activityId, isCompleted: isCompleted, badgeEarned: badgeEarned));
  }
}
