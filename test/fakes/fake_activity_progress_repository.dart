import 'package:bipod_bondhu/core/error/result.dart';
import 'package:bipod_bondhu/domain/repositories/activity_progress_repository.dart';

/// In-memory [ActivityProgressRepository] test double.
class FakeActivityProgressRepository implements ActivityProgressRepository {
  final Map<String, bool> completedByActivity = {};

  @override
  Future<Result<bool>> isActivityCompleted(String activityId) async =>
      Success(completedByActivity[activityId] ?? false);

  @override
  Future<Result<void>> markActivityCompleted(String activityId) async {
    completedByActivity[activityId] = true;
    return const Success(null);
  }
}
