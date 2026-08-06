import '../../core/error/result.dart';
import '../entities/activity.dart';
import '../repositories/activity_repository.dart';

/// Loads a single activity by id, for screens that only need one (e.g. the
/// Emergency Kit Builder) rather than the whole Activities list.
final class GetActivity {
  const GetActivity(this._activityRepository);

  final ActivityRepository _activityRepository;

  Future<Result<Activity>> call(String activityId) => _activityRepository.getActivity(activityId);
}
