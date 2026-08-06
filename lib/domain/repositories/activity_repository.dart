import '../../core/error/result.dart';
import '../entities/activity.dart';

/// Read access to the static cross-cutting activity content bundled as JSON
/// manifests. Implemented in the data layer by `ActivityRepositoryImpl`.
abstract interface class ActivityRepository {
  /// Loads every activity listed in `AppConstants.implementedActivities`.
  Future<Result<List<Activity>>> getActivities();

  /// Loads a single activity by its id (e.g. `"emergency_kit"`).
  Future<Result<Activity>> getActivity(String activityId);
}
