import 'package:equatable/equatable.dart';

/// A child's progress through one [HazardModule]. This is derived state:
/// [completedBeatIds] and [badgeEarned] come from Floor, while [isCompleted]
/// is computed by comparing [completedBeatIds] against the module's static
/// beat list, so completion is never duplicated into the database.
final class ModuleProgress extends Equatable {
  const ModuleProgress({
    required this.moduleId,
    required this.completedBeatIds,
    required this.isCompleted,
    required this.badgeEarned,
  });

  /// No beats completed yet, module not started.
  factory ModuleProgress.initial(String moduleId) => ModuleProgress(
        moduleId: moduleId,
        completedBeatIds: const {},
        isCompleted: false,
        badgeEarned: false,
      );

  final String moduleId;
  final Set<String> completedBeatIds;
  final bool isCompleted;
  final bool badgeEarned;

  @override
  List<Object?> get props => [moduleId, completedBeatIds, isCompleted, badgeEarned];
}
