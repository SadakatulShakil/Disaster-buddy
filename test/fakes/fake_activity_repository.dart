import 'package:bipod_bondhu/core/error/result.dart';
import 'package:bipod_bondhu/domain/entities/activity.dart';
import 'package:bipod_bondhu/domain/repositories/activity_repository.dart';

/// In-memory [ActivityRepository] test double backed by a fixed activity
/// list.
class FakeActivityRepository implements ActivityRepository {
  FakeActivityRepository(this.activities);

  final List<Activity> activities;

  @override
  Future<Result<Activity>> getActivity(String activityId) async {
    for (final activity in activities) {
      if (activity.id == activityId) return Success(activity);
    }
    throw StateError('No fake activity registered for "$activityId"');
  }

  @override
  Future<Result<List<Activity>>> getActivities() async => Success(activities);
}
