import 'package:equatable/equatable.dart';

/// A child's progress on one [Activity]. Unlike [ModuleProgress], completion
/// is a single persisted flag rather than derived from a list of beats —
/// activities have no beats.
final class ActivityProgress extends Equatable {
  const ActivityProgress({
    required this.activityId,
    required this.isCompleted,
    required this.badgeEarned,
  });

  /// Not started yet.
  factory ActivityProgress.initial(String activityId) => ActivityProgress(
        activityId: activityId,
        isCompleted: false,
        badgeEarned: false,
      );

  final String activityId;
  final bool isCompleted;
  final bool badgeEarned;

  @override
  List<Object?> get props => [activityId, isCompleted, badgeEarned];
}
