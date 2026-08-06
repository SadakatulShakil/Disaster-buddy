import 'package:floor/floor.dart';

/// A child's persisted progress on one cross-cutting activity (e.g. the
/// Emergency Kit Builder). Separate from [ProgressEntity] because activity
/// completion is a single flag, not derived from a list of module beats.
@Entity(tableName: 'activity_progress', primaryKeys: ['activityId'])
class ActivityProgressEntity {
  const ActivityProgressEntity({
    required this.activityId,
    required this.isCompleted,
    this.bestScore,
    required this.updatedAt,
  });

  final String activityId;
  final bool isCompleted;

  /// Reserved for future scored activities; unused (always null) by the
  /// Emergency Kit Builder, which has no score — only complete/not yet.
  final int? bestScore;

  /// Epoch millis.
  final int updatedAt;
}
