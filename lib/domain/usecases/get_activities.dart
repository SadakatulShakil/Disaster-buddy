import '../../core/error/result.dart';
import '../entities/activity.dart';
import '../repositories/activity_repository.dart';

/// Loads every implemented cross-cutting activity for the Activities entry
/// point.
final class GetActivities {
  const GetActivities(this._activityRepository);

  final ActivityRepository _activityRepository;

  Future<Result<List<Activity>>> call() => _activityRepository.getActivities();
}
